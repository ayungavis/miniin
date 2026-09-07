import MiniinCore
import Testing

@Suite("Engine router")
struct EngineRouterTests {
    private let router = EngineRouter()

    @Test("An MP4 H.264 source to MP4 H.264 selects AVFoundation")
    func nativeSourceSelectsAVFoundation() throws {
        let selection = try router.route(
            source: Self.source(),
            device: Self.device(),
            configuration: Self.configuration()
        )

        #expect(Self.engine(of: selection) == .avFoundation)
    }

    @Test("A Matroska source selects FFmpeg")
    func matroskaSourceSelectsFFmpeg() throws {
        let selection = try router.route(
            source: Self.source(container: .mkv),
            device: Self.device(),
            configuration: Self.configuration()
        )

        #expect(Self.engine(of: selection) == .ffmpeg)
    }

    @Test("A WebM source with VP9 selects FFmpeg")
    func webmVP9SelectsFFmpeg() throws {
        let selection = try router.route(
            source: Self.source(container: .webm, videoCodec: .vp9, audioCodec: .opus),
            device: Self.device(),
            configuration: Self.configuration()
        )

        #expect(Self.engine(of: selection) == .ffmpeg)
    }

    @Test("An unreadable container is reported by name")
    func unreadableContainerIsNamed() throws {
        let container = SourceContainer("flv")
        let selection = try router.route(
            source: Self.source(container: container),
            device: Self.device(),
            configuration: Self.configuration()
        )

        #expect(Self.reason(of: selection) == .sourceContainerUnreadable(container))
    }

    @Test("An unreadable video codec is reported by name")
    func unreadableVideoCodecIsNamed() throws {
        let codec = SourceVideoCodec("theora")
        let selection = try router.route(
            source: Self.source(videoCodec: codec),
            device: Self.device(),
            configuration: Self.configuration()
        )

        #expect(Self.reason(of: selection) == .sourceVideoCodecUnreadable(codec))
    }

    @Test("An unreadable audio codec is reported when audio is wanted")
    func unreadableAudioCodecIsNamed() throws {
        let codec = SourceAudioCodec("amr")
        let selection = try router.route(
            source: Self.source(audioCodec: codec),
            device: Self.device(),
            configuration: Self.configuration()
        )

        #expect(Self.reason(of: selection) == .sourceAudioCodecUnreadable(codec))
    }

    @Test("Removing audio ignores an unreadable audio codec")
    func removedAudioIgnoresUnreadableAudioCodec() throws {
        let selection = try router.route(
            source: Self.source(audioCodec: SourceAudioCodec("amr")),
            device: Self.device(),
            configuration: Self.configuration(audio: .removed)
        )

        #expect(Self.engine(of: selection) == .avFoundation)
    }

    @Test("Preserving HDR into H.264 is refused")
    func hdrIntoH264IsRefused() throws {
        let selection = try router.route(
            source: Self.source(dynamicRange: .hdr),
            device: Self.device(),
            configuration: Self.configuration(codec: .h264, dynamicRange: .preserve)
        )

        #expect(Self.reason(of: selection) == .hdrNotSupportedByOutputCodec(.h264))
    }

    @Test("Preserving HDR on a device without HDR export is refused")
    func hdrOnDeviceWithoutHDRExportIsRefused() throws {
        let selection = try router.route(
            source: Self.source(dynamicRange: .hdr),
            device: Self.device(supportsHDRExport: false),
            configuration: Self.configuration(codec: .hevc, dynamicRange: .preserve)
        )

        #expect(Self.reason(of: selection) == .hdrNotSupportedByDevice)
    }

    @Test("Requiring a hardware encoder the device lacks is refused")
    func requiredHardwareEncoderIsRefusedWhenAbsent() throws {
        let selection = try router.route(
            source: Self.source(),
            device: Self.device(encoders: []),
            configuration: Self.configuration(hardwareAcceleration: .requireHardware)
        )

        #expect(Self.reason(of: selection) == .hardwareEncoderUnavailable(.h264))
    }

    @Test("Tone mapping applies only to a known HDR source")
    func toneMappingRequiresKnownHDR() throws {
        let device = Self.device()
        let configuration = try Self.configuration(dynamicRange: .convertToSDR)

        let hdr = try router.route(
            source: Self.source(dynamicRange: .hdr),
            device: device,
            configuration: configuration
        )
        let unknown = try router.route(
            source: Self.source(dynamicRange: .unknown),
            device: device,
            configuration: configuration
        )

        #expect(Self.plan(of: hdr)?.requiresToneMapping == true)
        #expect(Self.plan(of: unknown)?.requiresToneMapping == false)
    }

    @Test("The encoder falls back to software when the device lacks hardware support")
    func encoderReflectsDeviceSupport() throws {
        let configuration = try Self.configuration()

        let accelerated = try router.route(
            source: Self.source(),
            device: Self.device(encoders: [.h264]),
            configuration: configuration
        )
        let unaccelerated = try router.route(
            source: Self.source(),
            device: Self.device(encoders: []),
            configuration: configuration
        )

        #expect(Self.plan(of: accelerated)?.videoEncoder == .hardware)
        #expect(Self.plan(of: unaccelerated)?.videoEncoder == .software)
    }

    @Test("The plan is identical whichever engine is selected")
    func planIsIndependentOfEngine() throws {
        let device = Self.device()
        let configuration = try Self.configuration()

        let native = try router.route(
            source: Self.source(),
            device: device,
            configuration: configuration
        )
        let fallback = try router.route(
            source: Self.source(container: .mkv),
            device: device,
            configuration: configuration
        )

        #expect(Self.engine(of: native) == .avFoundation)
        #expect(Self.engine(of: fallback) == .ffmpeg)
        #expect(Self.plan(of: native) == Self.plan(of: fallback))
    }
}

extension EngineRouterTests {
    enum SelectedEngine: Equatable {
        case avFoundation
        case ffmpeg
        case unsupported
    }

    static func engine(of selection: EngineSelection) -> SelectedEngine {
        switch selection {
        case .avFoundation: .avFoundation
        case .ffmpeg: .ffmpeg
        case .unsupported: .unsupported
        }
    }

    static func plan(of selection: EngineSelection) -> ExportPlan? {
        switch selection {
        case let .avFoundation(plan), let .ffmpeg(plan): plan
        case .unsupported: nil
        }
    }

    static func reason(of selection: EngineSelection) -> IncompatibilityReason? {
        guard case let .unsupported(reason) = selection else { return nil }

        return reason
    }

    static func source(
        container: SourceContainer = .mp4,
        videoCodec: SourceVideoCodec = .h264,
        dynamicRange: SourceDynamicRange = .sdr,
        audioCodec: SourceAudioCodec? = .aac
    ) throws -> SourceCapabilities {
        let dimensions = try #require(PixelDimensions(width: 1920, height: 1080))

        return SourceCapabilities(
            container: container,
            video: SourceVideoTrack(
                codec: videoCodec,
                dimensions: dimensions,
                frameRate: .fps30,
                dynamicRange: dynamicRange,
                rotation: .upright
            ),
            audio: audioCodec.map { SourceAudioTrack(codec: $0, channelCount: 2) }
        )
    }

    static func configuration(
        container: OutputContainer = .mp4,
        codec: OutputVideoCodec = .h264,
        dynamicRange: DynamicRangePolicy = .convertToSDR,
        audio: AudioConfiguration? = nil,
        hardwareAcceleration: HardwareAccelerationPreference = .allowSoftwareFallback
    ) throws -> ExportConfiguration {
        let resolution = try #require(PixelDimensions(width: 1920, height: 1080))
        let videoBitrate = try #require(Bitrate(bitsPerSecond: 4_000_000))
        let audioBitrate = try #require(Bitrate(bitsPerSecond: 128_000))

        let encodedAudio = AudioConfiguration.encoded(
            settings: AudioSettings(codec: .aac, bitrate: audioBitrate, channels: .stereo)
        )

        return ExportConfiguration(
            container: container,
            video: VideoConfiguration(
                codec: codec,
                resolution: resolution,
                frameRate: .fps30,
                rateControl: .averageBitrate(target: videoBitrate),
                dynamicRange: dynamicRange
            ),
            audio: audio ?? encodedAudio,
            metadata: .strip,
            hardwareAcceleration: hardwareAcceleration
        )
    }

    static func device(
        encoders: Set<OutputVideoCodec> = [.h264, .hevc],
        supportsHDRExport: Bool = true
    ) -> DeviceCapabilities {
        DeviceCapabilities(hardwareVideoEncoders: encoders, supportsHDRExport: supportsHDRExport)
    }
}
