public struct InspectedMedia: Sendable, Hashable {
    public let capabilities: SourceCapabilities
    public let filename: String
    public let fileSizeBytes: Int64
    public let duration: Duration
    public let videoBitrate: Bitrate?
    public let audioBitrate: Bitrate?

    public init(
        capabilities: SourceCapabilities,
        filename: String,
        fileSizeBytes: Int64,
        duration: Duration,
        videoBitrate: Bitrate?,
        audioBitrate: Bitrate?
    ) {
        self.capabilities = capabilities
        self.filename = filename
        self.fileSizeBytes = fileSizeBytes
        self.duration = duration
        self.videoBitrate = videoBitrate
        self.audioBitrate = audioBitrate
    }
}
