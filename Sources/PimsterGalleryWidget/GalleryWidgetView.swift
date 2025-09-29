import SwiftUI
import WebKit
import PimsterEmbedCore

/// SwiftUI view for Gallery Widget using WebView
@available(iOS 13.0, *)
public struct GalleryWidgetView: View {
    
    @ObservedObject var controller: GalleryWidget
    
    public var body: some View {
        GalleryWebView(
            previewUrl: controller.previewUrl,
            onStoryOpen: controller.onStoryOpen,
        )
        .frame(height: CGFloat(controller.config.height ?? 100)).sheet(isPresented: $controller.isPlayerVisible) {
            controller.storyPlayer!.createWebView()
        }
    }
}

/// WebView wrapper for Gallery Widget
private struct GalleryWebView: UIViewRepresentable {
    
    let previewUrl: String
    let onStoryOpen: (StoryOpenPayload) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Add message handler for JavaScript communication
        configuration.userContentController.add(context.coordinator, name: "pimsterHandler")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = true
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
        
        var parent: GalleryWebView
        var webView: WKWebView?
        
        init(_ parent: GalleryWebView) {
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
