public struct QualityLevel: Sendable, Hashable, Codable {
    public let percent: Int

    public init?(percent: Int) {
        guard (0 ... 100).contains(percent) else { return nil }
        self.percent = percent
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let percent = try container.decode(Int.self)

        guard let level = QualityLevel(percent: percent) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Quality level must be between 0 and 100"
            )
        }

        self = level
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(percent)
    }
}
