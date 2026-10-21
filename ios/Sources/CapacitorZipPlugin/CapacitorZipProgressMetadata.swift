import Foundation

public struct CapacitorZipProgressMetadata {
    public let operationId: String
    public let source: String
    public let destination: String

    public init(operationId: String, source: String, destination: String) {
        self.operationId = operationId
        self.source = source
        self.destination = destination
    }
}
