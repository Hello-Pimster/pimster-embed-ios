import Foundation
import WebKit

/// Wrapper to make any response Sendable for concurrency
private struct SendableResponse<T>: @unchecked Sendable {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}

/// Type-erased message handler
private struct AnyMessageHandler {
    let handle: ([String: Any]?) -> Void
    
    init<M: Message>(_ type: M.Type, _ handler: @escaping (M.Payload) -> M.Response) where M.Payload: JsonInitializable {
        self.handle = { payloadDict in
            do {
                // Convert [String: Any] to Data for JSON parsing
                let payloadData: Data
                if let payloadDict = payloadDict {
                    payloadData = try JSONSerialization.data(withJSONObject: payloadDict, options: [])
                } else {
                    // Handle Void payload case
                    payloadData = "{}".data(using: .utf8) ?? Data()
                }
                
                let payload = try M.Payload.fromJson(payloadData)
                let response = handler(payload)
                
                // Send response if there's a response type defined
                if let responseName = M.responseName {
                    // Wrap response in SendableResponse to bypass strict concurrency checking
                    // since we know the response objects are safe to send
                    let sendableResponse = SendableResponse(response)
                    DispatchQueue.main.async {
                        MessageSender.sendResponse(responseName: responseName, response: sendableResponse.value)
                    }
                }
            } catch {
                print("PimsterEmbed: Failed to process message payload: \(error)")
            }
        }
    }
    
    init<M: Message>(_ type: M.Type, _ handler: @escaping (M.Payload) -> M.Response) where M.Payload: VoidPayload {
        self.handle = { payloadDict in
            let payload = M.Payload.fromVoid()
            let response = handler(payload)
            
            // Send response if there's a response type defined
            if let responseName = M.responseName {
                // Wrap response in SendableResponse to bypass strict concurrency checking
                // since we know the response objects are safe to send
                let sendableResponse = SendableResponse(response)
                DispatchQueue.main.async {
                    MessageSender.sendResponse(responseName: responseName, response: sendableResponse.value)
                }
            }
        }
    }
}

/// Message handler utility for processing WebView messages
public class MessageHandler {
    
    /// WebView reference for sending responses
    private weak var webView: WKWebView?
    
    /// Type-erased message handlers
    private var eventHandlerMap: [MessageNames: AnyMessageHandler] = [:]
    
    public init() {}

    /// Set an event handler for a specific message type
    /// - Parameters:
    ///   - type: The message type to handle
    ///   - callback: The callback function to execute when the message is received
    public func setEventHandler<M: Message>(_ type: M.Type, _ callback: @escaping (M.Payload) -> M.Response) where M.Payload: JsonInitializable {
        self.eventHandlerMap[M.name] = AnyMessageHandler(type, callback)
    }
    
    /// Set an event handler for a specific message type with Void payload
    /// - Parameters:
    ///   - type: The message type to handle
    ///   - callback: The callback function to execute when the message is received
    public func setEventHandler<M: Message>(_ type: M.Type, _ callback: @escaping (M.Payload) -> M.Response) where M.Payload: VoidPayload {
        self.eventHandlerMap[M.name] = AnyMessageHandler(type, callback)
    }

    /// Set the WebView reference for sending responses
    public func setWebView(_ webView: WKWebView) {
        self.webView = webView
        DispatchQueue.main.async {
            MessageSender.setWebView(webView)
        }
    }
    
    /// Process a message from WebView
    /// - Parameter message: The message data from WebView
    public func processMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else {
            print("PimsterEmbed: Invalid message format - missing 'type' field")
            return
        }
        
        let payload = message["payload"] as? [String: Any]
        
        // Handle internal messages
        if let messageType = MessageNames(rawValue: type) {
            if let handler = eventHandlerMap[messageType] {
                handler.handle(payload)
            }
            else {
                print("PimsterEmbed: Missing handler for message type \(type)")
            }
        }
        else {
            print("PimsterEmbed: Unknown message type: \(type)")
        }
    }
}
