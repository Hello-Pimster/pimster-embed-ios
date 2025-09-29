import Foundation

// MARK: - Impression Event Payload

/// Payload for impression events matching web implementation
public struct ImpressionEventPayload: Encodable, Sendable {
    public let widgetType: WidgetType
    public let company: String
    public let product: String?
    public let locale: String?
    public let moduleId: String?
    public let storyId: String?
    public let isAutoplay: Bool?
    
    public init(
        widgetType: WidgetType,
        company: String,
        product: String? = nil,
        locale: String? = nil,
        moduleId: String? = nil,
        storyId: String? = nil,
        isAutoplay: Bool? = nil
    ) {
        self.widgetType = widgetType
        self.company = company
        self.product = product
        self.locale = locale
        self.moduleId = moduleId
        self.storyId = storyId
        self.isAutoplay = isAutoplay
    }
}

// MARK: - Open Event Payload

/// Payload for open events matching web implementation
public struct OpenEventPayload: Encodable, Sendable {
    public let widgetType: WidgetType
    public let company: String
    public let product: String
    public let locale: String?
    public let cookieConsent: String
    public let skipOnboarding: Bool?
    public let moduleId: String?
    public let story: String?
    
    public init(
        widgetType: WidgetType,
        company: String,
        product: String,
        locale: String? = nil,
        cookieConsent: String = "accepted",
        skipOnboarding: Bool? = nil,
        moduleId: String? = nil,
        story: String? = nil
    ) {
        self.widgetType = widgetType
        self.company = company
        self.product = product
        self.locale = locale
        self.cookieConsent = cookieConsent
        self.skipOnboarding = skipOnboarding
        self.moduleId = moduleId
        self.story = story
    }
}

// MARK: - Close Event Payload

/// Payload for close events matching web implementation
public struct CloseEventPayload: Encodable, Sendable {
    public let widgetType: WidgetType
    public let company: String
    public let product: String
    public let storyId: String
    public let display: StoryPreviewDisplay
    public let placement: StickyPlacement?
    public let animations: [StoryPreviewAnimation]
    
    public init(
        widgetType: WidgetType,
        company: String,
        product: String,
        storyId: String,
        display: StoryPreviewDisplay,
        placement: StickyPlacement? = nil,
        animations: [StoryPreviewAnimation] = []
    ) {
        self.widgetType = widgetType
        self.company = company
        self.product = product
        self.storyId = storyId
        self.display = display
        self.placement = placement
        self.animations = animations
    }
}
