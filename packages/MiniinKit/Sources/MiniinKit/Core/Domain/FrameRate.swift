public struct FrameRate: Sendable, Hashable, Codable {
    public let numerator: Int
    public let denominator: Int

    public var value: Double {
        Double(numerator) / Double(denominator)
    }

    public init?(numerator: Int, denominator: Int) {
        guard numerator > 0, denominator > 0 else { return nil }
        let divisor = Self.greatestCommonDivisor(numerator, denominator)
        self.numerator = numerator / divisor
        self.denominator = denominator / divisor
    }

    private init(reduced numerator: Int, over denominator: Int) {
        self.numerator = numerator
        self.denominator = denominator
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let numerator = try container.decode(Int.self, forKey: .numerator)
        let denominator = try container.decode(Int.self, forKey: .denominator)

        guard let rate = FrameRate(numerator: numerator, denominator: denominator) else {
            throw DecodingError.dataCorruptedError(
                forKey: .numerator,
                in: container,
                debugDescription: "Frame rate must have a positive numerator and denominator"
            )
        }

        self = rate
    }

    private static func greatestCommonDivisor(_ first: Int, _ second: Int) -> Int {
        var first = first
        var second = second
        while second != 0 {
            (first, second) = (second, first % second)
        }
        return first
    }
}

public extension FrameRate {
    static let fps24NTSC = FrameRate(reduced: 24000, over: 1001)
    static let fps24 = FrameRate(reduced: 24, over: 1)
    static let fps25 = FrameRate(reduced: 25, over: 1)
    static let fps30NTSC = FrameRate(reduced: 30000, over: 1001)
    static let fps30 = FrameRate(reduced: 30, over: 1)
    static let fps50 = FrameRate(reduced: 50, over: 1)
    static let fps60NTSC = FrameRate(reduced: 60000, over: 1001)
    static let fps60 = FrameRate(reduced: 60, over: 1)
}
