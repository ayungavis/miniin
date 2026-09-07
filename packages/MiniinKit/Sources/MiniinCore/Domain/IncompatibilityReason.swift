public enum IncompatibilityReason: Sendable, Hashable {
    case sourceContainerUnreadable(SourceContainer)
    case sourceVideoCodecUnreadable(SourceVideoCodec)
    case sourceAudioCodecUnreadable(SourceAudioCodec)
    case hdrNotSupportedByOutputCodec(OutputVideoCodec)
    case hdrNotSupportedByDevice
    case hardwareEncoderUnavailable(OutputVideoCodec)
    case engineUnavailable(ProcessingEngine)
}

public extension IncompatibilityReason {
    var code: String {
        switch self {
        case .sourceContainerUnreadable: "source.container"
        case .sourceVideoCodecUnreadable: "source.videoCodec"
        case .sourceAudioCodecUnreadable: "source.audioCodec"
        case .hdrNotSupportedByOutputCodec: "hdr.codec"
        case .hdrNotSupportedByDevice: "hdr.device"
        case .hardwareEncoderUnavailable: "hardware.encoder"
        case .engineUnavailable: "engine.unavailable"
        }
    }
}
