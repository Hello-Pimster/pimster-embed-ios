import Foundation

/// Analytics event constants matching the web implementation
public enum AnalyticsEvents: String, CaseIterable, Sendable {
    case impression = "Embed Impression"
    case open = "Embed Open"
    case close = "Embed Close"
}
