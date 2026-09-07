public enum AVFoundationSupport {
    public static let readableContainers: Set<SourceContainer> = [
        .mp4, .mov, .m4v
    ]

    public static let readableVideoCodecs: Set<SourceVideoCodec> = [
        .h264, .hevc, .proRes, .mpeg4
    ]

    public static let readableAudioCodecs: Set<SourceAudioCodec> = [
        .aac, .alac, .pcm, .mp3
    ]

    public static let writableFormats: Set<OutputFormat> = [
        OutputFormat(container: .mp4, codec: .h264),
        OutputFormat(container: .mp4, codec: .hevc),
        OutputFormat(container: .mov, codec: .h264),
        OutputFormat(container: .mov, codec: .hevc)
    ]
}
