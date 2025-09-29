public struct ProductVariant: JsonInitializable, Sendable {
  public let id: String
  public let gtin: String?
  public let source: Source
  
  public init(id: String, gtin: String?, source: Source) {
    self.id = id
    self.gtin = gtin
    self.source = source
  }
}

public struct Product: JsonInitializable, Sendable {
  public let id: String
  public let source: Source
  
  public init(id: String, source: Source) {
    self.id = id
    self.source = source
  }
}

public struct Source: JsonInitializable, Sendable {
  public let provider: String
  public let metadata: [String: String]
  
  public init(provider: String, metadata: [String: String]) {
    self.provider = provider
    self.metadata = metadata
  }
}

public struct AddToCartPayload: JsonInitializable, Sendable {
  public let variant: ProductVariant
  public let product: Product
  
  public init(variant: ProductVariant, product: Product) {
    self.variant = variant
    self.product = product
  }
}


public struct AddToCartResponse: Encodable, Sendable {
    public let success: Bool
    public let error: String?
    
    public init(success: Bool, error: String? = nil) {
        self.success = success
        self.error = error
    }
    
    /// Create a successful response
    public static func success() -> AddToCartResponse {
        return AddToCartResponse(success: true)
    }
    
    /// Create an error response
    public static func error(_ message: String) -> AddToCartResponse {
        return AddToCartResponse(success: false, error: message)
    }
}

struct AddToCart: Message {
  nonisolated(unsafe) static var name: MessageNames = .addToCart
  typealias Payload = AddToCartPayload
  nonisolated(unsafe) static var responseName: MessageNames? = .addToCartResponse
  typealias Response = AddToCartResponse
}
