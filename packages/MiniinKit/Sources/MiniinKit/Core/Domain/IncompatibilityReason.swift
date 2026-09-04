public enum IncompatibilityReason: Sendable, Hashable {
    case sourceContainerUnreadable(SourceContainer)
    case sourceVideoCodecUnreadable(SourceVideoCodec)
    case hdrNotSupportedByOutputCodec(OutputVideoCodec)
    case hdrNotSupportedByDevice
    case hardwareEncoderUnavailable(OutputVideoCodec)
}
