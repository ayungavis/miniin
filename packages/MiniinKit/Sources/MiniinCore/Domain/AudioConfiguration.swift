public enum AudioConfiguration: Sendable, Hashable, Codable {
    case removed
    case encoded(settings: AudioSettings)
}

public struct AudioSettings: Sendable, Hashable, Codable {
    public var codec: OutputAudioCodec
    public var bitrate: Bitrate
    public var channels: AudioChannels

    public init(codec: OutputAudioCodec, bitrate: Bitrate, channels: AudioChannels) {
        self.codec = codec
        self.bitrate = bitrate
        self.channels = channels
    }
}

public enum AudioChannels: String, Sendable, Codable, CaseIterable {
    case mono
    case stereo
}
