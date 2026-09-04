public protocol MediaIdentifier: Sendable, Hashable, Codable {
    var identifier: String { get }

    init(_ identifier: String)
}

public extension MediaIdentifier {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let identifier = try container.decode(String.self)

        self.init(identifier)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(identifier)
    }
}
