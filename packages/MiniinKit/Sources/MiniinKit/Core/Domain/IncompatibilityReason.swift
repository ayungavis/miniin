public enum IncompatibilityReason: Sendable, Hashable {
    case sourceContainerUnreadable(SourceContainer)
    case sourceVideoCodecUnreadable(SourceVideoCodec)
    case sourceAudioCodecUnreadable(SourceAudioCodec)
    case hdrNotSupportedByOutputCodec(OutputVideoCodec)
    case hdrNotSupportedByDevice
    case hardwareEncoderUnavailable(OutputVideoCodec)
    case engineUnavailable(ProcessingEngine)
}
