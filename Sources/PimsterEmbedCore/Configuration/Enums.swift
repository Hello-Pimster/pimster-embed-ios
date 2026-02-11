import Foundation

// MARK: - Story Preview Display

/// Story preview display modes
public enum StoryPreviewDisplay: String, CaseIterable, Encodable, Sendable {
    case round, square
}

// MARK: - Story Preview Animation

/// Story preview animation types
public enum StoryPreviewAnimation: String, CaseIterable, Encodable, Sendable {
    case pulse, autoplay, onHover
}

// MARK: - Gallery Justify

/// Gallery justification options
public enum GalleryJustify: String, CaseIterable, Encodable, Sendable {
    case left, right, center, evenly
}

// MARK: - Sticky Placement

/// Sticky widget placement options
public enum StickyPlacement: String, CaseIterable, Encodable, Sendable {
    case topLeft, topRight, bottomLeft, bottomRight
}

// MARK: - Widget Type

/// Widget type identifiers
public enum WidgetType: String, CaseIterable, Encodable, Sendable {
    case gallery, stickyStory, feed
}

