import Foundation
#if os(iOS)
import UIKit
#endif

/// Protocol for providing custom context information to analytics
@available(iOS 13.0, *)
public protocol AnalyticsContextProvider: Sendable {
    /// Get current screen/view context
    var currentScreen: String? { get }
    
    /// Get custom app context
    var appContext: [String: Sendable] { get }
    
    /// Create a new context provider with screen information
    @MainActor
    func setAppInfo(currentScreen: String?) -> AnalyticsContextProvider
}

/// Internal default implementation
@available(iOS 13.0, *)
internal struct DefaultAnalyticsContextProvider: AnalyticsContextProvider {
    public let currentScreen: String?
    public let appContext: [String: Sendable]
    
    public init(currentScreen: String? = nil, appContext: [String: Sendable] = [:]) {
        self.currentScreen = currentScreen
        self.appContext = appContext
    }
    
    /// Create context provider with app information
    @MainActor
    public init() {
        var context: [String: Sendable] = [:]
        
        // Add app information
        if let bundleId = Bundle.main.bundleIdentifier {
            context["bundleId"] = bundleId
        }
        
        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            context["appName"] = appName
        }
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            context["appVersion"] = appVersion
        }
        
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            context["buildNumber"] = buildNumber
        }
        
        // Add device information
        #if os(iOS)
        context["deviceModel"] = UIDevice.current.model
        context["systemName"] = UIDevice.current.systemName
        context["systemVersion"] = UIDevice.current.systemVersion
        
        // Add screen information
        let screen = UIScreen.main
        context["screenWidth"] = Int(screen.bounds.width)
        context["screenHeight"] = Int(screen.bounds.height)
        context["screenScale"] = screen.scale
        
        // Add device orientation
        context["deviceOrientation"] = UIDevice.current.orientation.rawValue
        #endif
        
        self.currentScreen = nil
        self.appContext = context
    }
    
    /// Create a new context provider with screen information
    @MainActor
    public func setAppInfo(currentScreen: String?) -> AnalyticsContextProvider {
        return DefaultAnalyticsContextProvider(
            currentScreen: currentScreen ?? self.currentScreen,
            appContext: self.appContext
        )
    }
}

/// Analytics context information
@available(iOS 13.0, *)
public struct AnalyticsContext: Sendable {
    public let page: [String: Sendable]
    public let userAgent: String
    public let locale: String
    public let library: [String: Sendable]
    public let timezone: String
    public let project: String
    public let app: [String: Sendable]
    public let device: [String: Sendable]
    
    public init(
        page: [String: Sendable],
        userAgent: String,
        locale: String,
        library: [String: Sendable],
        timezone: String,
        project: String,
        app: [String: Sendable],
        device: [String: Sendable]
    ) {
        self.page = page
        self.userAgent = userAgent
        self.locale = locale
        self.library = library
        self.timezone = timezone
        self.project = project
        self.app = app
        self.device = device
    }
    
    /// Create analytics context from provider
    public static func from(provider: AnalyticsContextProvider) -> AnalyticsContext {
        let currentScreen = provider.currentScreen ?? "Unknown"
        
        // Extract app and device info from provider
        let appInfo = provider.appContext
        let bundleId = appInfo["bundleId"] as? String ?? "unknown"
        let appName = appInfo["appName"] as? String ?? "iOS App"
        let appVersion = appInfo["appVersion"] as? String ?? "1.0.0"
        
        // Create page context
        let page: [String: Sendable] = [
            "path": "/\(currentScreen.lowercased().replacingOccurrences(of: " ", with: "-"))",
            "referrer": "",
            "search": "",
            "title": "\(appName) - \(currentScreen)",
            "url": "ios://\(bundleId)/\(currentScreen.lowercased().replacingOccurrences(of: " ", with: "-"))",
            "hash": "",
            "screen": currentScreen
        ]
        
        // Create app context
        let app: [String: Sendable] = [
            "name": appName,
            "version": appVersion,
            "bundleId": bundleId,
            "buildNumber": appInfo["buildNumber"] as? String ?? "1"
        ]
        
        // Create device context
        let device: [String: Sendable] = [
            "model": appInfo["deviceModel"] as? String ?? "iOS Device",
            "os": appInfo["systemName"] as? String ?? "iOS",
            "osVersion": appInfo["systemVersion"] as? String ?? "13.0",
            "screenWidth": appInfo["screenWidth"] as? Int ?? 375,
            "screenHeight": appInfo["screenHeight"] as? Int ?? 667,
            "screenScale": appInfo["screenScale"] as? CGFloat ?? 2.0,
            "orientation": appInfo["deviceOrientation"] as? Int ?? 1
        ]
        
        return AnalyticsContext(
            page: page,
            userAgent: "PimsterEmbed-iOS/1.0.0 (\(appName)/\(appVersion))",
            locale: Locale.current.identifier,
            library: [
                "name": "pimster-embed-ios",
                "version": "1.0.0"
            ],
            timezone: TimeZone.current.identifier,
            project: "pimster-widget",
            app: app,
            device: device
        )
    }
}
