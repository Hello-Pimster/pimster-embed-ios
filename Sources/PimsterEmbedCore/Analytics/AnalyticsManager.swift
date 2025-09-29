import Foundation
import Dispatch
#if os(iOS)
import UIKit
#endif

@available(iOS 13.0, *)
public final class AnalyticsManager: @unchecked Sendable {
    
    /// Shared instance for singleton access
    public static let shared = AnalyticsManager()
    
    /// Current configuration (access only on `queue`)
    private var config: PimsterConfig?
    
    /// Whether analytics is initialized (access only on `queue`)
    private var isInitialized = false
    
    /// Analytics session ID (access only on `queue`)
    private var sessionId: String?
    
    /// Context provider for enhanced analytics (access only on `queue`)
    private var contextProvider: AnalyticsContextProvider?
    
    /// Internal serialization queue for thread-safety
    private let queue = DispatchQueue(label: "com.pimster.analytics", qos: .utility)
    
    private init() {}
    
    /// Configure analytics with package configuration
    /// - Parameter config: Package configuration
    public func configure(with config: PimsterConfig) {
        queue.async {
            self.config = config
            if !self.isInitialized {
                self.initializeAnalyticsLocked()
            }
        }
    }
    
    /// Set context provider for enhanced analytics
    /// - Parameter provider: Context provider for app and view information
    public func setContextProvider(_ provider: AnalyticsContextProvider) {
        queue.async {
            self.contextProvider = provider
        }
    }
    
    /// Set current screen for analytics context
    /// - Parameter currentScreen: Current screen/view name
    @MainActor
    public func setCurrentScreen(_ currentScreen: String?) {
        self.queue.async {
            if let existingProvider = self.contextProvider {
                // Enhance existing provider
                Task { @MainActor in
                    let enhancedProvider = existingProvider.setAppInfo(currentScreen: currentScreen)
                    self.contextProvider = enhancedProvider
                }
            } else {
                // Create new provider with screen info
                Task { @MainActor in
                    let newProvider = DefaultAnalyticsContextProvider().setAppInfo(currentScreen: currentScreen)
                    self.contextProvider = newProvider
                }
            }
        }
    }
    
    /// Initialize analytics system
    private func initializeAnalyticsLocked() {
        guard let config = self.config else { return }
        
        self.sessionId = UUID().uuidString
        self.isInitialized = true
        
        // Automatically set up default context provider with sensible values
        if self.contextProvider == nil {
            Task { @MainActor in
                let defaultProvider = DefaultAnalyticsContextProvider()
                self.setContextProvider(defaultProvider)
            }
        }
    }
    
    /// Track widget impression using web-compatible payload
    /// - Parameter payload: Impression event payload
    public func trackImpression(_ payload: ImpressionEventPayload) {
        queue.async {
            self.trackEventLocked(AnalyticsEvents.impression.rawValue, properties: self.encodePayload(payload))
        }
    }
    
    /// Track story open event using web-compatible payload
    /// - Parameter payload: Open event payload
    public func trackOpen(_ payload: OpenEventPayload) {
        queue.async {
            self.trackEventLocked(AnalyticsEvents.open.rawValue, properties: self.encodePayload(payload))
        }
    }
    
    /// Track dialog close event using web-compatible payload
    /// - Parameter payload: Close event payload
    public func trackClose(_ payload: CloseEventPayload) {
        queue.async {
            self.trackEventLocked(AnalyticsEvents.close.rawValue, properties: self.encodePayload(payload))
        }
    }
    
    
    /// Track generic event
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - properties: Event properties
    private func trackEventLocked(_ eventName: String, properties: [String: Any]) {
        guard let _ = self.config, self.isInitialized else { return }
        
        // Generate anonymous ID for this session
        let anonymousId = self.sessionId ?? UUID().uuidString
        
        // Create meta information
        let meta: [String: Any] = [
            "rid": UUID().uuidString,
            "ts": Int64(Date().timeIntervalSince1970 * 1000), // timestamp in milliseconds
            "hasCallback": false
        ]
        
        // Create enhanced context using provider or defaults
        let analyticsContext: AnalyticsContext
        if let provider = self.contextProvider {
            analyticsContext = AnalyticsContext.from(provider: provider)
        } else {
            // Fallback to default context with basic app info
            // This creates a minimal context without UI device access
            let fallbackProvider = DefaultAnalyticsContextProvider(
                currentScreen: nil,
                appContext: [
                    "bundleId": Bundle.main.bundleIdentifier ?? "unknown",
                    "appName": Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "iOS App",
                    "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                    "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                ]
            )
            analyticsContext = AnalyticsContext.from(provider: fallbackProvider)
        }
        
        let context: [String: Any] = [
            "page": analyticsContext.page as [String: Any],
            "userAgent": analyticsContext.userAgent,
            "locale": analyticsContext.locale,
            "library": analyticsContext.library as [String: Any],
            "timezone": analyticsContext.timezone,
            "project": analyticsContext.project,
            "app": analyticsContext.app as [String: Any],
            "device": analyticsContext.device as [String: Any]
        ]
        
        let event = AnalyticsEvent(
            type: "track",
            event: eventName,
            properties: properties,
            options: [:],
            userId: nil,
            anonymousId: anonymousId,
            meta: meta,
            context: context
        )
        
        self.sendAnalyticsEvent(event)
    }
    
    /// Encode payload struct to dictionary for analytics
    /// - Parameter payload: Any payload struct
    /// - Returns: Dictionary representation
    private func encodePayload<T: Encodable>(_ payload: T) -> [String: Any] {
        do {
            let data = try JSONEncoder().encode(payload)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any] ?? [:]
        } catch {
            print("PimsterEmbed Analytics Error: Failed to encode payload: \(error)")
            return [:]
        }
    }
    
    /// Send analytics event to server
    /// - Parameter event: Analytics event to send
    private func sendAnalyticsEvent(_ event: AnalyticsEvent) {
        // Create URL request using environment-based analytics URL
        guard let url = URL(string: Constants.analyticsUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = event.encode() else {
            print("PimsterEmbed Analytics Error: Failed to encode event")
            return
        }
        
        request.httpBody = jsonData
        
        // Send request asynchronously
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("PimsterEmbed Analytics Error: \(error.localizedDescription)")
            }
        }.resume()
    }
}

// MARK: - Analytics Event Models

/// Analytics event structure matching web implementation
internal struct AnalyticsEvent {
    let type: String
    let event: String
    let properties: [String: Any]
    let options: [String: Any]
    let userId: String?
    let anonymousId: String
    let meta: [String: Any]
    let context: [String: Any]
    
    func encode() -> Data? {
        let eventData: [String: Any] = [
            "type": type,
            "event": event,
            "properties": jsonSafeDictionary(properties),
            "options": jsonSafeDictionary(options),
            "userId": userId as Any,
            "anonymousId": anonymousId,
            "meta": jsonSafeDictionary(meta),
            "context": jsonSafeDictionary(context)
        ]
        
        return try? JSONSerialization.data(withJSONObject: eventData)
    }

    private func jsonSafeValue(_ value: Any) -> Any {
        if value is NSNull { return value }
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number }
        if let bool = value as? Bool { return bool }
        if let intVal = value as? Int { return intVal }
        if let doubleVal = value as? Double { return doubleVal }
        if let floatVal = value as? Float { return floatVal }
        if let date = value as? Date { return ISO8601DateFormatter().string(from: date) }
        if let url = value as? URL { return url.absoluteString }
        if let array = value as? [Any] { return array.map { jsonSafeValue($0) } }
        if let dict = value as? [String: Any] { return jsonSafeDictionary(dict) }
        if let convertible = value as? CustomStringConvertible { return convertible.description }
        return String(describing: value)
    }

    private func jsonSafeDictionary(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = jsonSafeValue(value)
        }
        return result
    }
}


