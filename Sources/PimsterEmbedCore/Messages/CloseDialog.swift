public struct CloseDialog: Message {
  nonisolated(unsafe) public static var name: MessageNames = .closeDialog
  public typealias Payload = EmptyPayload
  nonisolated(unsafe) public static var responseName: MessageNames? = nil
  public typealias Response = EmptyPayload
}