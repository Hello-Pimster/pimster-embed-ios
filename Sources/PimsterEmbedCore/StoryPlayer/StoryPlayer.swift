import Foundation
import SwiftUI

/// Internal class for managing story playback
@available(iOS 13.0, *)
public class StoryPlayer: NSObject {
    
    /// Analytics manager for tracking
    private let analyticsManager: AnalyticsManager
    
    /// Configuration
    private let config: PimsterConfig
    
    /// Add-to-cart callback that returns a response
    private var onAddToCart: ((AddToCartPayload) -> AddToCartResponse)?
    
    /// Story close callback
    private var onStoryClose: (() -> Void)?
    
    /// Current URL displayed in the webview
    private var currentUrl: String
    
    /// Initialize Story Player
    public init(config: PimsterConfig, analyticsManager: AnalyticsManager) {
        self.config = config
        self.analyticsManager = analyticsManager
        self.currentUrl = ""
        super.init()
    }
    
    /// Create WebView for story playback
    /// - Returns: WebView instance (placeholder for now)
    @MainActor
    public func createWebView() -> StoryPlayerView {
        return StoryPlayerView(url: self.currentUrl, onAddToCart: self.onAddToCart, onClose: self.onStoryClose)
    }
    
    /// Load story content
    public func loadStory(payload : StoryOpenPayload) {
        let domain = Constants.pimUrlTemplate.replacingOccurrences(of: "{{company}}", with: config.company) // use url_template to build the url, replace company
        
        var params: [String: String] = [
            "utm_source": "app",
            "utm_medium": "iframe",
            "cookie_consent": "accepted",
            "bundle": "story",
            "skip_onboarding": "true"
        ]
        
        if payload.moduleId != nil {
            params["module"] = "\(payload.moduleId!)"
        }
       
        
        let queryParams = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        // Create story URL using environment-based embed server URL (inject locale if provided)
        let localeSegment = (payload.locale?.isEmpty == false) ? "/\(payload.locale!)" : ""
        let storyUrl = "\(domain)\(localeSegment)/\(config.product)/story/\(payload.story)?\(queryParams)"

        self.currentUrl = storyUrl
    }
    
    /// Set add-to-cart callback that returns a response
    public func setAddToCartCallback(_ callback: @escaping (AddToCartPayload) -> AddToCartResponse) {
        self.onAddToCart = callback
    }
    
    /// Set story close callback
    public func setStoryCloseCallback(_ callback: @escaping () -> Void) {
        self.onStoryClose = callback
    }
    
    /// Cleanup resources
    func cleanup() {
        onAddToCart = nil
        onStoryClose = nil
    }
}


public struct StoryOpenPayload {
    public let story : String
    public let product : String?
    public let moduleId: Int?
    public let locale: String?
    
    public init(story: String, product: String?, moduleId: Int?, locale: String?) {
        self.story = story
        self.product = product
        self.moduleId = moduleId
        self.locale = locale
    }
}
