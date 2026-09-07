public struct OutputFormat: Sendable, Hashable {
    public let container: OutputContainer
    public let codec: OutputVideoCodec

    public init(container: OutputContainer, codec: OutputVideoCodec) {
        self.container = container
        self.codec = codec
    }
}
