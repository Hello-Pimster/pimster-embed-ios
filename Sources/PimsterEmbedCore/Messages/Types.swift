import Foundation

public protocol Message {
  static var name : MessageNames { get }
  associatedtype Payload
  static var responseName: MessageNames? { get }
  associatedtype Response: Encodable
}


public protocol JsonInitializable: Decodable {
    static func fromJson(_ data: Data) throws -> Self
}

extension JsonInitializable {
    public static func fromJson(_ data: Data) throws -> Self {
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from: data)
    }
}

// Special protocol for Void payloads that don't need JSON parsing
public protocol VoidPayload {
    static func fromVoid() -> Self
}

// Create a wrapper type for Void to avoid tuple extension issues
public struct EmptyPayload: VoidPayload, Encodable, Sendable {
    public static func fromVoid() -> EmptyPayload {
        return EmptyPayload()
    }
}
