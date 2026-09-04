public struct SourceAudioTrack: Sendable, Hashable, Codable {
    public let codec: SourceAudioCodec
    public let channelCount: Int

    public init(codec: SourceAudioCodec, channelCount: Int) {
        self.codec = codec
        self.channelCount = channelCount
    }
}
