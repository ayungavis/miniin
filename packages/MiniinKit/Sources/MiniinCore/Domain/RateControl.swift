public enum RateControl: Sendable, Hashable, Codable {
    case averageBitrate(target: Bitrate)
    case constantQuality(level: QualityLevel)
}
