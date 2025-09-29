import SwiftUI
import WebKit
import PimsterEmbedCore

/// SwiftUI view for Sticky Widget using WebView
@available(iOS 13.0, *)
public struct StickyWidgetView: View {
    
    @ObservedObject var controller: StickyWidget
    
    
    public var body: some View {
            if controller.isVisible {
                GeometryReader { geometry in
                    ZStack(alignment: .topTrailing) {
                        // WebView for sticky content
                        StickyWebView(
                            previewUrl: controller.previewUrl,
                            onStoryOpen: controller.onStoryOpen,
                        )
                        .frame(width: CGFloat(controller.config.width ?? 100), height: CGFloat(controller.config.height ?? 100))

                        // Close button overlay pinned to top-right of the webview
                        Button(action: controller.onClosePreview) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle().fill(Color.black.opacity(0.6))
                                )
                        }
                        .offset(x: 7, y: -7)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .position(widgetPosition(in: geometry, placement: controller.config.placement ?? StickyPlacement.bottomRight))
                }.sheet(isPresented: $controller.isPlayerVisible) {
                    controller.storyPlayer!.createWebView()
                }
            }
        
    }
    
    /// Calculate widget position based on placement
    /// - Parameters:
    ///   - geometry: Geometry proxy for screen dimensions
    ///   - placement: Widget placement position
    /// - Returns: CGPoint for widget position
    private func widgetPosition(in geometry: GeometryProxy, placement: StickyPlacement) -> CGPoint {
        let padding: CGFloat = 20
        let widgetWidth: CGFloat = CGFloat(controller.config.width ?? 80)
        let widgetHeight: CGFloat = CGFloat(controller.config.height ?? 80)
        
        switch placement {
        case .bottomRight:
            return CGPoint(
                x: geometry.size.width - padding - widgetWidth/2,
                y: geometry.size.height - padding - widgetHeight/2
            )
        case .bottomLeft:
            return CGPoint(
                x: padding + widgetWidth/2,
                y: geometry.size.height - padding - widgetHeight/2
            )
        case .topRight:
            return CGPoint(
                x: geometry.size.width - padding - widgetWidth/2,
                y: padding + widgetHeight/2
            )
        case .topLeft:
            return CGPoint(
                x: padding + widgetWidth/2,
                y: padding + widgetHeight/2
            )
        }
    }
}

/// WebView wrapper for Sticky Widget
private struct StickyWebView: UIViewRepresentable {
    
    let previewUrl: String
    let onStoryOpen: (StoryOpenPayload) -> Void
    
    func makeUIView(context: UIViewRepresentableContext<StickyWebView>) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Add message handler for JavaScript communication
        configuration.userContentController.add(context.coordinator, name: "pimsterHandler")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        context.coordinator.webView = webView
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: UIViewRepresentableContext<StickyWebView>) {
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
        
        var parent: StickyWebView
        var webView: WKWebView?
        
        init(_ parent: StickyWebView) {
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
                    let moduleId = payload["moduleId"] as? Int
                    let product = payload["product"] as? String
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
