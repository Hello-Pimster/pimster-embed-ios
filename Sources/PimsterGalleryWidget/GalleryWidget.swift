import Foundation
import UIKit
import WebKit
import SwiftUI
import PimsterEmbedCore

/// Gallery Widget for displaying a carousel or grid of stories using WebView
@available(iOS 13.0, *)
public class GalleryWidget: NSObject, ObservableObject {

    /// Analytics manager for tracking
    private let analyticsManager: AnalyticsManager

    /// Widget configuration
    @Published var config: GalleryWidgetConfig

    // Preview
    /// Preview URL
    @Published var previewUrl: String = "about:blank"
    
    // Player
    @Published var storyPlayer: StoryPlayer?

    /// StoryPlayer visible
    @Published var isPlayerVisible: Bool = false

    /// Add-to-cart callback that returns a response
    @Published var addToCartCallback: ((AddToCartPayload) -> AddToCartResponse)?
    
    
    /// Initialize Gallery Widget
    /// - Parameter config: Widget configuration including company, product, etc.
    public init(config: GalleryWidgetConfig, addToCartCallback: @escaping (AddToCartPayload) -> AddToCartResponse) {
        
        self.config = config
        self.addToCartCallback = addToCartCallback
        self.analyticsManager = AnalyticsManager.shared
        super.init()

        self.previewUrl = buildEmbedUrl()
        
        // Configure analytics with widget config
        let pimsterConfig = PimsterConfig(
            company: config.company,
            product: config.product,
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
        GalleryWidgetView(controller : self)
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

    /// Build embed server URL with configuration
    private func buildEmbedUrl() -> String {
        // Build the path similar to web component
        let path = "/company/\(config.company)/product/\(config.product)/module/\(config.moduleId)"
        
        // Build configuration object
        var configObject: [String: Any] = [:]
        if config.animations != nil {configObject["animations"] = config.animations!.map{$0.rawValue}}
        if config.borderColor != nil {configObject["borderColor"] = config.borderColor}
        if config.display != nil {configObject["display"] = config.display!.rawValue}
        if config.justify != nil {configObject["justify"] = config.justify!.rawValue}
        if config.withPlayIcon != nil {configObject["withPlayIcon"] = config.withPlayIcon}
        if config.withRadius != nil {configObject["withRadius"] = config.withRadius}
        if config.withTitle != nil {configObject["withStoryTitle"] = config.withTitle}
        
        
        // Encode configuration
        if let configData = try? JSONSerialization.data(withJSONObject: configObject),
           let configString = String(data: configData, encoding: .utf8) {
            let encodedConfig = configString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(Constants.embedServerUrl)\(path)?options=\(encodedConfig)"
        }
        
        return "\(Constants.embedServerUrl)\(path)"
    }

    public func onStoryOpen(payload : StoryOpenPayload) {
        if(self.storyPlayer == nil) { return }
        self.storyPlayer!.loadStory( payload: payload)
        self.isPlayerVisible = true
        
        // Track story open with web-compatible payload
        let openPayload = OpenEventPayload(
            widgetType: .gallery,
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
        // Gallery widgets don't track close events in the web implementation
    }

    /// Set add-to-cart callback
    /// - Parameter callback: Callback function
    public func onAddToCart(addToCartPayload: AddToCartPayload) -> AddToCartResponse {
        return self.addToCartCallback?(addToCartPayload) ?? AddToCartResponse.success()
    }

    
    // MARK: - Private Methods
    
    /// Track widget impression
    private func trackImpression() {
        // Determine if autoplay is enabled by checking if autoplay animation is included
        let isAutoplay = config.animations?.contains(.autoplay) ?? false
        
        let impressionPayload = ImpressionEventPayload(
            widgetType: .gallery,
            company: config.company,
            product: config.product,
            moduleId: String(config.moduleId),
            isAutoplay: isAutoplay
        )
        analyticsManager.trackImpression(impressionPayload)
    }
}
