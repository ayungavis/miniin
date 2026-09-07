public struct SourceAudioCodec: MediaIdentifier, Hashable {
    public let identifier: String

    public init(_ identifier: String) {
        self.identifier = identifier
    }
}

public extension SourceAudioCodec {
    static let aac = SourceAudioCodec("aac")
    static let mp3 = SourceAudioCodec("mp3")
    static let opus = SourceAudioCodec("opus")
    static let vorbis = SourceAudioCodec("vorbis")
    static let alac = SourceAudioCodec("alac")
    static let pcm = SourceAudioCodec("pcm")
}
