public enum OutputContainer: String, Sendable, Codable, CaseIterable {
    case mp4
    case mov

    public var fileExtension: String {
        switch self {
        case .mp4: "mp4"
        case .mov: "mov"
        }
    }
}
