import Foundation

/// Configuration for the Pimster Embed package
/// Contains only user-configurable attributes (URLs come from environment)
public struct PimsterConfig: Sendable {
    public let company: String
    public let product: String

    public init(
        company: String,
        product: String? = nil
    ) {
        self.company = company
        self.product = product ?? "default"
    }
}
// MARK: - Base

public protocol WidgetConfig {
    var company: String { get }
    var product: String { get }
    var borderColor: String? { get }
    var animations: [StoryPreviewAnimation]? { get }
    var display: StoryPreviewDisplay? { get }
    var withPlayIcon: Bool? { get }
    var withRadius: Bool? { get }
    var withTitle: Bool? { get }
}

// MARK: - Gallery "type equivalent"

public protocol GallerySpecificConfig {
    var moduleId: Int { get }
    var justify: GalleryJustify? { get }
    /// Height of the gallery widget container in points
    var height: Double? { get }
}

public typealias IGalleryWidgetConfig = WidgetConfig & GallerySpecificConfig

// Example concrete value conforming to the "type"
public struct GalleryWidgetConfig: IGalleryWidgetConfig {
    public let company: String
    public let moduleId: Int
    public let product: String
    
    public let borderColor: String?
    public let animations: [StoryPreviewAnimation]?
    public let display: StoryPreviewDisplay?
    public let withPlayIcon: Bool?
    public let withRadius: Bool?
    public let withTitle: Bool?
    public let justify: GalleryJustify?
    public let height: Double?
    

    public init(
        company: String,
        moduleId: Int,
        product: String? = nil,
        borderColor: String? = nil,
        animations: [StoryPreviewAnimation]? = nil,
        display: StoryPreviewDisplay? = nil,
        withPlayIcon: Bool? = nil,
        withRadius: Bool? = nil,
        withTitle: Bool? = nil,
        justify: GalleryJustify? = nil,
        height: Double? = nil,

    ) {
        self.company = company
        self.product = product ?? "default"
        self.moduleId = moduleId
        self.borderColor = borderColor
        self.animations = animations
        self.display = display
        self.withPlayIcon = withPlayIcon
        self.withRadius = withRadius
        self.withTitle = withTitle
        self.justify = justify
        self.height = height
    }
}

// MARK: - Feed "type equivalent"

public protocol FeedSpecificConfig {
    var moduleId: Int { get }
    var gap: Double? { get }
    var columns: Int? { get }
}

public typealias IFeedWidgetConfig = WidgetConfig & FeedSpecificConfig

// Example concrete value conforming to the "type"
public struct FeedWidgetConfig: IFeedWidgetConfig {
    public let company: String
    public let moduleId: Int
    public let product: String
    
    public let borderColor: String?
    public let animations: [StoryPreviewAnimation]?
    public let display: StoryPreviewDisplay?
    public let withPlayIcon: Bool?
    public let withRadius: Bool?
    public let withTitle: Bool?
    public let gap: Double?
    public let columns: Int?
    
    public init(
        company: String,
        moduleId: Int,
        product: String? = nil,
        borderColor: String? = nil,
        animations: [StoryPreviewAnimation]? = nil,
        display: StoryPreviewDisplay? = nil,
        withPlayIcon: Bool? = nil,
        withRadius: Bool? = nil,
        withTitle: Bool? = nil,
        gap: Double? = nil,
        columns: Int? = nil
    ) {
        self.company = company
        self.product = product ?? "default"
        self.moduleId = moduleId
        self.borderColor = borderColor
        self.animations = animations
        self.display = display
        self.withPlayIcon = withPlayIcon
        self.withRadius = withRadius
        self.withTitle = withTitle
        self.gap = gap
        self.columns = columns
    }
}

// MARK: - Sticky "type equivalent"

public protocol StickySpecificConfig {
    var storyId: Int { get }
    var placement: StickyPlacement? { get }
    /// Width of the sticky widget container in points
    var width: Double? { get }
    /// Height of the sticky widget container in points
    var height: Double? { get }
}

public typealias IStickyWidgetType = WidgetConfig & StickySpecificConfig

// Example concrete value conforming to the "type"
public struct StickyWidgetConfig: IStickyWidgetType {
    public let company: String
    public let storyId: Int
    public let product: String
    
    public let placement: StickyPlacement?
    public let animations: [StoryPreviewAnimation]?
    public let borderColor: String?
    public let display: StoryPreviewDisplay?
    public let withPlayIcon: Bool?
    public let withRadius: Bool?
    public let withTitle: Bool?
    public let width: Double?
    public let height: Double?

    public init(
        company: String,
        storyId: Int,
        product: String? = nil,
        borderColor: String? = nil,
        animations: [StoryPreviewAnimation]? = nil,
        display: StoryPreviewDisplay? = nil,
        withPlayIcon: Bool? = nil,
        withRadius: Bool? = nil,
        withTitle: Bool? = nil,
        placement: StickyPlacement? = nil,
        width: Double? = nil,
        height: Double? = nil,
    ) {
        self.company = company
        self.product = product ?? "default"
        self.storyId = storyId
        self.borderColor = borderColor
        self.animations = animations
        self.display = display
        self.withPlayIcon = withPlayIcon
        self.withRadius = withRadius
        self.withTitle = withTitle
        self.placement = placement
        self.width = width
        self.height = height
    }
}
