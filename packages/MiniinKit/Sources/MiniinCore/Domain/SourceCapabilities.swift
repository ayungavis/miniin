public struct SourceCapabilities: Sendable, Hashable, Codable {
    public let container: SourceContainer
    public let video: SourceVideoTrack
    public let audio: SourceAudioTrack?

    public init(container: SourceContainer, video: SourceVideoTrack, audio: SourceAudioTrack?) {
        self.container = container
        self.video = video
        self.audio = audio
    }
}
