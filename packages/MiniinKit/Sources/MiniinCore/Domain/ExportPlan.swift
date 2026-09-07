public struct ExportPlan: Sendable, Hashable {
    public let videoEncoder: VideoEncoder
    public let requiresToneMapping: Bool

    public init(videoEncoder: VideoEncoder, requiresToneMapping: Bool) {
        self.videoEncoder = videoEncoder
        self.requiresToneMapping = requiresToneMapping
    }
}

public enum VideoEncoder: String, Sendable, CaseIterable {
    case hardware
    case software
}
