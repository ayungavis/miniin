public struct Bitrate: Sendable, Hashable, Codable {
    public let bitsPerSecond: Int

    public init?(bitsPerSecond: Int) {
        guard bitsPerSecond > 0 else { return nil }
        self.bitsPerSecond = bitsPerSecond
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let bitsPerSecond = try container.decode(Int.self)

        guard let bitrate = Bitrate(bitsPerSecond: bitsPerSecond) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Bitrate must be positive"
            )
        }

        self = bitrate
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(bitsPerSecond)
    }
}
