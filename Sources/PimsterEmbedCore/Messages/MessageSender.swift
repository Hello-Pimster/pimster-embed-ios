import Foundation
import WebKit

/// Utility for sending messages to WebView
public class MessageSender {
    
    /// Shared WebView reference for sending responses
    @MainActor
    private static weak var webView: WKWebView?
    
    /// Set the WebView reference for sending responses
    @MainActor
    public static func setWebView(_ webView: WKWebView) {
        MessageSender.webView = webView
    }
    
    /// Send a generic message to the WebView
    /// - Parameters:
    ///   - webView: The WebView to send the message to
    ///   - messageType: The type of message to send
    ///   - payload: The message payload
    @MainActor
    private static func sendMessage(to webView: WKWebView, messageType: MessageNames, payload: [String: Any]) {
        do {
            let message: [String: Any] = [
                "type": messageType.rawValue,
                "payload": payload,
                "source": "pimster-embed"
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            
            let script = """
            if (window.postMessage) {
                window.postMessage(\(jsonString), '*');
            }
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("PimsterEmbed: Failed to send message to WebView: \(error)")
                }
            }
        } catch {
            print("PimsterEmbed: Failed to serialize message: \(error)")
        }
    }
    
    /// Send a response message using the shared WebView reference
    /// - Parameters:
    ///   - responseName: The response message type
    ///   - response: The response object to send
    @MainActor
    public static func sendResponse<T: Encodable>(responseName: MessageNames, response: T) {
        guard let webView = webView else {
            print("PimsterEmbed: No WebView reference available for sending response")
            return
        }
        
        do {
            // Convert response to JSON
            let responseData = try JSONEncoder().encode(response)
            let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] ?? [:]
            
            sendMessage(to: webView, messageType: responseName, payload: responseDict)
        } catch {
            print("PimsterEmbed: Failed to encode response: \(error)")
        }
    }
}
