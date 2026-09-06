public struct DeviceCapabilities: Sendable, Hashable {
    public let hardwareVideoEncoders: Set<OutputVideoCodec>
    public let supportsHDRExport: Bool

    public init(
        hardwareVideoEncoders: Set<OutputVideoCodec>,
        // tradeoff: HDR export is off until exporter carries the source transfer function, HLG or PQ
        supportsHDRExport: Bool = false
    ) {
        self.hardwareVideoEncoders = hardwareVideoEncoders
        self.supportsHDRExport = supportsHDRExport
    }
}
