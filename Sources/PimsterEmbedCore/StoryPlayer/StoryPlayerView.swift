import SwiftUI
import WebKit
#if os(iOS)
import UIKit
#endif

@available(iOS 13.0, *)
public struct StoryPlayerView: View {
    let url: String
    let onAddToCart: ((AddToCartPayload) -> AddToCartResponse)?
    let onClose: (() -> Void)?
    
    public init(url: String, onAddToCart: ((AddToCartPayload) -> AddToCartResponse)?, onClose: (() -> Void)?) {
        self.url = url
        self.onAddToCart = onAddToCart
        self.onClose = onClose
    }

    public var body: some View {
        #if os(iOS)
        PimsterWebView(
            url: URL(string: url)!,
            onAddToCart: onAddToCart,
            onClose: onClose
        )
        #else
        Text("WebView not supported on this platform")
        #endif
    }
    
}

#if os(iOS)
struct PimsterWebView: UIViewRepresentable {
    let url: URL
    let onAddToCart: ((AddToCartPayload) -> AddToCartResponse)?
    let onClose: (() -> Void)?

    @MainActor
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        #if os(iOS)
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.allowsAirPlayForMediaPlayback = false
        #endif
        
        configuration.userContentController.add(context.coordinator, name: "pimsterHandler")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        webView.load(URLRequest(url: url))
        return webView
    }

    @MainActor
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    @MainActor
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        private let parent: PimsterWebView
        private let messageHandler: MessageHandler

        init(_ parent: PimsterWebView) {
            self.parent = parent
            self.messageHandler = MessageHandler()
            super.init()
            
            // Set up message handler callbacks
            self.messageHandler.setEventHandler(AddToCart.self) { [weak self] product in
                return self?.parent.onAddToCart?(product) ?? AddToCartResponse.success()
            }
            
            self.messageHandler.setEventHandler(CloseDialog.self) { [weak self] _ in
                self?.parent.onClose?()
                return EmptyPayload()
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "pimsterHandler" else { return }
            guard let payload = message.body as? [String: Any] else { return }
            
            // Process message using the new message handler
            messageHandler.processMessage(payload)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Set the WebView reference for sending responses
            messageHandler.setWebView(webView)
            
            let script = """
            window.addEventListener('message', function(event) {
                if (!window.webkit || !window.webkit.messageHandlers || !window.webkit.messageHandlers.pimsterHandler) { return; }
                window.webkit.messageHandlers.pimsterHandler.postMessage(event.data);
            });
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
}
#endif

