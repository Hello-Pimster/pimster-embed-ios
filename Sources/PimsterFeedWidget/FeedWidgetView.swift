import SwiftUI
import UIKit
import WebKit
import PimsterEmbedCore

/// SwiftUI view for Feed Widget using WebView
@available(iOS 13.0, *)
public struct FeedWidgetView: View {
    
    @ObservedObject var controller: FeedWidget
    
    public var body: some View {
        FeedWebView(
            previewUrl: controller.previewUrl,
            onStoryOpen: controller.onStoryOpen,
            onResize: controller.onResize
        )
        .frame(height: controller.dynamicHeight)
        .sheet(isPresented: $controller.isPlayerVisible) {
            controller.storyPlayer!.createWebView()
        }
    }
}

/// WebView wrapper for Feed Widget
private struct FeedWebView: UIViewRepresentable {
    
    let previewUrl: String
    let onStoryOpen: (StoryOpenPayload) -> Void
    let onResize: (CGFloat) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Add message handler for JavaScript communication
        configuration.userContentController.add(context.coordinator, name: "pimsterHandler")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        // Height is driven by resize messages; parent ScrollView handles scrolling
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        context.coordinator.webView = webView
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Load the embed server URL with configuration
        let embedUrl = previewUrl
        if let url = URL(string: embedUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        var parent: FeedWebView
        var webView: WKWebView?
        
        init(_ parent: FeedWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Inject JavaScript to handle message communication
            injectMessageHandler()
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }
            
            switch type {
            case MessageNames.openDialog.rawValue:
                if
                    let payload = body["payload"] as? [String: Any],
                    let storyId = payload["story"] as? String
                {
                    let product = payload["product"] as? String
                    var moduleId: Int?
                    if let moduleIdString = payload["moduleId"] as? String { moduleId = Int(moduleIdString) }
                    let locale = payload["locale"] as? String
                    let storyOpenPayload = StoryOpenPayload(story: storyId, product: product, moduleId: moduleId, locale: locale)
                    parent.onStoryOpen(storyOpenPayload)
                }
            case MessageNames.resize.rawValue:
                // Handle resize message from embed server (height can be number or string e.g. "5221px")
                let payload = body["payload"] as? [String: Any]
                print("PimsterEmbed: resize message received, payload=\(payload ?? [:])")
                guard let payload = payload else { break }
                let resolvedHeight: CGFloat? = {
                    if let h = payload["height"] as? CGFloat { return h }
                    if let h = payload["height"] as? Int { return CGFloat(h) }
                    if let h = payload["height"] as? Double { return CGFloat(h) }
                    if let h = payload["height"] as? String {
                        let numericPart = h.trimmingCharacters(in: .letters).trimmingCharacters(in: .whitespaces)
                        return numericPart.isEmpty ? nil : CGFloat(Double(numericPart) ?? 0)
                    }
                    return nil
                }()
                if let height = resolvedHeight {
                    // Embed sends height in device pixels; convert to points for SwiftUI layout
                    let scale = UIScreen.main.scale
                    let heightInPoints = scale > 0 ? height / scale : height
                    print("PimsterEmbed: resize height=\(height)px -> \(heightInPoints)pt (scale=\(scale))")
                    parent.onResize(heightInPoints)
                } else {
                    print("PimsterEmbed: resize message missing or invalid height in payload")
                }
            default:
                break
            }
        }
        
        // MARK: - Private Methods
        
        private func injectMessageHandler() {
            let script = """
            window.addEventListener('message', function(event) {
                    window.webkit.messageHandlers.pimsterHandler.postMessage(event.data);
            });
            """
            
            webView?.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("PimsterEmbed: Failed to inject message handler - \(error.localizedDescription)")
                }
            }
        }
    }
}
