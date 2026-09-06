public struct SizeEstimate: Sendable, Hashable {
    public let lowerBytes: Int64
    public let upperBytes: Int64

    public var midpointBytes: Int64 {
        (lowerBytes + upperBytes) / 2
    }

    public init(lowerBytes: Int64, upperBytes: Int64) {
        self.lowerBytes = min(lowerBytes, upperBytes)
        self.upperBytes = max(lowerBytes, upperBytes)
    }
}
