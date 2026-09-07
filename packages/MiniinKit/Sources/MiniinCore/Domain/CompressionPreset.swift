public enum PresetCategory: String, Sendable, Codable, CaseIterable {
    case general
    case sharing
    case social
    case web
}

public enum PresetEntitlement: String, Sendable, Codable {
    case free
    case pro
}

public enum ResolutionRule: Sendable, Hashable, Codable {
    case matchSource
    case longestSideAtMost(Int)
}

public enum FrameRateRule: Sendable, Hashable, Codable {
    case matchSource
    case atMost(FrameRate)
}

public enum RateControlRule: Sendable, Hashable, Codable {
    case bitsPerPixel(Double)
    case constantQuality(percent: Int)
}

public enum AudioRule: Sendable, Hashable, Codable {
    case removed
    case encoded(codec: OutputAudioCodec, bitsPerSecond: Int, channels: AudioChannels)
}

public struct CompressionPreset: Sendable, Hashable, Codable, Identifiable {
    public let id: String
    public let category: PresetCategory
    public let entitlement: PresetEntitlement
    public let container: OutputContainer
    public let videoCodec: OutputVideoCodec
    public let resolution: ResolutionRule
    public let frameRate: FrameRateRule
    public let rateControl: RateControlRule
    public let audio: AudioRule
    public let metadata: MetadataPolicy

    public init(
        id: String,
        category: PresetCategory,
        entitlement: PresetEntitlement,
        container: OutputContainer,
        videoCodec: OutputVideoCodec,
        resolution: ResolutionRule,
        frameRate: FrameRateRule,
        rateControl: RateControlRule,
        audio: AudioRule,
        metadata: MetadataPolicy
    ) {
        self.id = id
        self.category = category
        self.entitlement = entitlement
        self.container = container
        self.videoCodec = videoCodec
        self.resolution = resolution
        self.frameRate = frameRate
        self.rateControl = rateControl
        self.audio = audio
        self.metadata = metadata
    }
}

public extension CompressionPreset {
    func resolve(
        for source: SourceCapabilities,
        allowUpscaling: Bool = false
    ) -> ExportConfiguration? {
        let dimensions = PresetResolution.dimensions(
            for: resolution,
            source: source.video.displayDimensions,
            allowUpscaling: allowUpscaling
        )
        let rate = PresetResolution.frameRate(for: frameRate, source: source.video.frameRate)

        guard
            let control = PresetResolution.rateControl(
                for: rateControl,
                dimensions: dimensions,
                frameRate: rate
            ),
            let audioConfiguration = PresetResolution.audio(for: audio)
        else {
            return nil
        }

        return ExportConfiguration(
            container: container,
            video: VideoConfiguration(
                codec: videoCodec,
                resolution: dimensions,
                frameRate: rate,
                rateControl: control,
                // tradeoff: every preset converts to SDR until presets carry a dynamic-range rule
                dynamicRange: .convertToSDR
            ),
            audio: audioConfiguration,
            metadata: metadata,
            hardwareAcceleration: .allowSoftwareFallback
        )
    }
}

public extension CompressionPreset {
    // tradeoff: 0.07 bits per pixel is a starting point, replace it once the Phase 0 estimation prototype measures one
    static let balanced1080p = CompressionPreset(
        id: "builtin.balanced.1080p",
        category: .general,
        entitlement: .free,
        container: .mp4,
        videoCodec: .h264,
        resolution: .longestSideAtMost(1920),
        frameRate: .matchSource,
        rateControl: .bitsPerPixel(0.07),
        audio: .encoded(codec: .aac, bitsPerSecond: 128_000, channels: .stereo),
        metadata: .strip
    )
}
