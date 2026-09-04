public struct SourceVideoCodec: MediaIdentifier, Hashable {
    public let identifier: String

    public init(_ identifier: String) {
        self.identifier = identifier
    }
}

public extension SourceVideoCodec {
    static let h264 = SourceVideoCodec("h264")
    static let hevc = SourceVideoCodec("hevc")
    static let vp9 = SourceVideoCodec("vp9")
    static let av1 = SourceVideoCodec("av1")
    static let mpeg4 = SourceVideoCodec("mpeg4")
    static let proRes = SourceVideoCodec("prores")
}
