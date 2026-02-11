import Foundation
import UIKit
import WebKit
import SwiftUI
import PimsterEmbedCore

/// Feed Widget for displaying a vertical feed of stories using WebView
@available(iOS 13.0, *)
public class FeedWidget: NSObject, ObservableObject {

    /// Analytics manager for tracking
    private let analyticsManager: AnalyticsManager

    /// Widget configuration
    @Published var config: FeedWidgetConfig

    // Preview
    /// Preview URL
    @Published var previewUrl: String = "about:blank"
    
    // Player
    @Published var storyPlayer: StoryPlayer?

    /// StoryPlayer visible
    @Published var isPlayerVisible: Bool = false

    /// Add-to-cart callback that returns a response
    @Published var addToCartCallback: ((AddToCartPayload) -> AddToCartResponse)?
    
    /// Dynamic height for content-driven sizing
    @Published var dynamicHeight: CGFloat = 400
    
    
    /// Initialize Feed Widget
    /// - Parameter config: Widget configuration including company, product, etc.
    public init(config: FeedWidgetConfig, addToCartCallback: @escaping (AddToCartPayload) -> AddToCartResponse) {
        
        self.config = config
        self.addToCartCallback = addToCartCallback
        self.analyticsManager = AnalyticsManager.shared
        super.init()

        self.previewUrl = buildFeedUrl()
        
        // Configure analytics with widget config
        let pimsterConfig = PimsterConfig(
            company: config.company,
            product: config.product
        )
        analyticsManager.configure(with: pimsterConfig)
        
        // Initialize story player
        self.storyPlayer = StoryPlayer(config: pimsterConfig, analyticsManager: analyticsManager)
        self.storyPlayer?.setAddToCartCallback(self.onAddToCart)
        self.storyPlayer?.setStoryCloseCallback(self.onStoryClose)

        trackImpression()
    }
    
    /// Create SwiftUI view for the widget
    /// - Returns: SwiftUI view
    public func createSwiftUIView() -> some View {
        FeedWidgetView(controller: self)
    }
    
    /// Create UIKit view for the widget
    /// - Returns: UIKit view controller
    @MainActor
    public func createUIKitView() -> UIViewController {
        let hostingController = UIHostingController(
            rootView: self.createSwiftUIView()
        )
        return hostingController
    }

    /// Build feed URL with configuration
    private func buildFeedUrl() -> String {
        // Build the path for feed widget
        let path = "/company/\(config.company)/product/\(config.product)/module/\(config.moduleId)/feed"
        
        // Build configuration object
        var configObject: [String: Any] = [:]
        if config.animations != nil { configObject["animations"] = config.animations!.map{$0.rawValue} }
        if config.borderColor != nil { configObject["borderColor"] = config.borderColor }
        if config.display != nil { configObject["display"] = config.display!.rawValue }
        if config.withPlayIcon != nil { configObject["withPlayIcon"] = config.withPlayIcon }
        if config.withRadius != nil { configObject["withRadius"] = config.withRadius }
        if config.withTitle != nil { configObject["withStoryTitle"] = config.withTitle }
        if config.gap != nil { configObject["gap"] = config.gap }
        if config.columns != nil { configObject["columns"] = config.columns }
        
        
        // Encode configuration
        if let configData = try? JSONSerialization.data(withJSONObject: configObject),
           let configString = String(data: configData, encoding: .utf8) {
            let encodedConfig = configString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(Constants.embedServerUrl)\(path)?options=\(encodedConfig)"
        }
        
        return "\(Constants.embedServerUrl)\(path)"
    }

    public func onStoryOpen(payload: StoryOpenPayload) {
        if self.storyPlayer == nil { return }
        self.storyPlayer!.loadStory(payload: payload)
        self.isPlayerVisible = true
        
        // Track story open with web-compatible payload
        let openPayload = OpenEventPayload(
            widgetType: .feed,
            company: config.company,
            product: config.product,
            locale: payload.locale,
            moduleId: payload.moduleId != nil ? String(payload.moduleId!) : nil,
            story: payload.story
        )
        analyticsManager.trackOpen(openPayload)
    }

    public func onStoryClose() {
        self.isPlayerVisible = false
        // Feed widgets don't track close events in the web implementation
    }

    /// Set add-to-cart callback
    /// - Parameter callback: Callback function
    public func onAddToCart(addToCartPayload: AddToCartPayload) -> AddToCartResponse {
        return self.addToCartCallback?(addToCartPayload) ?? AddToCartResponse.success()
    }

    /// Handle resize messages from embed server
    /// - Parameter height: New height in pixels
    public func onResize(height: CGFloat) {
        DispatchQueue.main.async {
            self.dynamicHeight = height
        }
    }
    
    // MARK: - Private Methods
    
    /// Track widget impression
    private func trackImpression() {
        // Determine if autoplay is enabled by checking if autoplay animation is included
        let isAutoplay = config.animations?.contains(.autoplay) ?? false
        
        let impressionPayload = ImpressionEventPayload(
            widgetType: .feed,
            company: config.company,
            product: config.product,
            moduleId: String(config.moduleId),
            isAutoplay: isAutoplay
        )
        analyticsManager.trackImpression(impressionPayload)
    }
}
