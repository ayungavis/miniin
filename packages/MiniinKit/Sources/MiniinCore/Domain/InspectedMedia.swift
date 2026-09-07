import Foundation

public struct InspectedMedia: Sendable, Hashable {
    public let capabilities: SourceCapabilities
    public let url: URL
    public let fileSizeBytes: Int64
    public let duration: Duration
    public let videoBitrate: Bitrate?
    public let audioBitrate: Bitrate?

    public var filename: String {
        url.lastPathComponent
    }

    public init(
        capabilities: SourceCapabilities,
        url: URL,
        fileSizeBytes: Int64,
        duration: Duration,
        videoBitrate: Bitrate?,
        audioBitrate: Bitrate?
    ) {
        self.capabilities = capabilities
        self.url = url
        self.fileSizeBytes = fileSizeBytes
        self.duration = duration
        self.videoBitrate = videoBitrate
        self.audioBitrate = audioBitrate
    }
}
