import Foundation

/// Environment-based constants for the Pimster Embed package
public struct Constants {
    
    // MARK: - Environment Configuration
    
    /// Current environment
    public static let environment: String = Environment.environment
    
    // MARK: - API URLs
    
    /// GraphQL API URL
    public static let graphqlUrl: String = Environment.graphqlUrl
    
    /// AWS CloudFront URL for media assets
    public static let awsCfUrl: String = Environment.awsCfUrl
    
    /// Embed server URL
    public static let embedServerUrl: String = Environment.embedServerUrl

    /// Pimster URL template
    public static let pimUrlTemplate: String = Environment.pimUrlTemplate
    
    // MARK: - Analytics URLs
    
    /// Analytics endpoint URL
    public static let analyticsUrl: String = Environment.analyticsUrl
    
    // MARK: - Default Values
    
    /// Default product
    public static let defaultProduct = "default"
    
    /// Default animations
    public static let defaultAnimations: [StoryPreviewAnimation] = []
    
    /// Default display mode
    public static let defaultDisplay = StoryPreviewDisplay.round
    
    /// Default border color
    public static let defaultBorderColor = "#000000"
    
    /// Default with play icon
    public static let defaultWithPlayIcon = true
    
    /// Default with radius
    public static let defaultWithRadius = true
    
    /// Default with story title
    public static let defaultWithStoryTitle = true
    
    /// Default gallery justify
    public static let defaultGalleryJustify = GalleryJustify.center
    
    /// Default sticky placement
    public static let defaultStickyPlacement = StickyPlacement.bottomRight
}
