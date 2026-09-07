public struct DeviceCapabilities: Sendable, Hashable {
    public let hardwareVideoEncoders: Set<OutputVideoCodec>
    public let supportsHDRExport: Bool

    public init(
        hardwareVideoEncoders: Set<OutputVideoCodec>,
        supportsHDRExport: Bool
    ) {
        self.hardwareVideoEncoders = hardwareVideoEncoders
        self.supportsHDRExport = supportsHDRExport
    }
}
