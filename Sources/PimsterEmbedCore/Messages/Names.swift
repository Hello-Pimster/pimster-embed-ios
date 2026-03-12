// MARK: - Internal Message Types

/// Internal message types for iframe communication
public enum MessageNames: String, CaseIterable, Sendable {
    case addToCart = "addToCart"
    case addToCartResponse = "addToCartResponse"
    case closeDialog = "closeDialog"
    case openDialog = "openDialog"
    case resize = "resize"
}
