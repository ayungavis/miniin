import MiniinCore
import Testing

@Suite("Compression preset")
struct CompressionPresetTests {
    @Test("Matching the source returns its display dimensions")
    func matchingSourceReturnsDisplayDimensions() throws {
        let source = try Self.dimensions(1280, 720)
        let result = PresetResolution.dimensions(
            for: .matchSource,
            source: source,
            allowUpscaling: false
        )

        #expect(result == source)
    }

    @Test("A source inside the cap is left alone")
    func sourceInsideTheCapIsLeftAlone() throws {
        let source = try Self.dimensions(1280, 720)
        let result = PresetResolution.dimensions(
            for: .longestSideAtMost(1920),
            source: source,
            allowUpscaling: false
        )

        #expect(result == source)
    }

    @Test("Enabling upscaling enlarges a smaller source")
    func enablingUpscalingEnlargesASmallerSource() throws {
        let result = try PresetResolution.dimensions(
            for: .longestSideAtMost(1920),
            source: Self.dimensions(1280, 720),
            allowUpscaling: true
        )

        #expect(result.width == 1920)
        #expect(result.height == 1080)
    }

    @Test("A 4K source scales to the cap and keeps its aspect ratio")
    func fourKScalesToTheCap() throws {
        let result = try PresetResolution.dimensions(
            for: .longestSideAtMost(1920),
            source: Self.dimensions(3840, 2160),
            allowUpscaling: false
        )

        #expect(result.width == 1920)
        #expect(result.height == 1080)
    }

    @Test("Resolved dimensions are always even")
    func resolvedDimensionsAreAlwaysEven() throws {
        let result = try PresetResolution.dimensions(
            for: .longestSideAtMost(1000),
            source: Self.dimensions(1999, 1001),
            allowUpscaling: false
        )

        #expect(result.width.isMultiple(of: 2))
        #expect(result.height.isMultiple(of: 2))
    }

    @Test("A rotated source resolves to a portrait output")
    func rotatedSourceResolvesPortrait() throws {
        let track = try Self.track(1920, 1080, rotation: .quarterTurn)
        let result = PresetResolution.dimensions(
            for: .longestSideAtMost(1280),
            source: track.displayDimensions,
            allowUpscaling: false
        )

        #expect(result.width < result.height)
        #expect(result.height == 1280)
    }

    @Test("Bits per pixel scales the bitrate with the resolution")
    func bitsPerPixelScalesWithResolution() throws {
        let large = try #require(
            try PresetResolution.rateControl(
                for: .bitsPerPixel(0.1),
                dimensions: Self.dimensions(1920, 1080),
                frameRate: .fps30
            )
        )
        let small = try #require(
            try PresetResolution.rateControl(
                for: .bitsPerPixel(0.1),
                dimensions: Self.dimensions(960, 540),
                frameRate: .fps30
            )
        )

        guard
            case let .averageBitrate(largeTarget) = large,
            case let .averageBitrate(smallTarget) = small
        else {
            Issue.record("expected average bitrate")
            return
        }

        #expect(largeTarget.bitsPerSecond == smallTarget.bitsPerSecond * 4)
    }

    @Test("Frame rate is capped or preserved exactly")
    func frameRateIsCappedOrPreserved() {
        #expect(PresetResolution.frameRate(for: .atMost(.fps30), source: .fps60) == .fps30)
        #expect(PresetResolution.frameRate(for: .atMost(.fps60), source: .fps30) == .fps30)
        #expect(PresetResolution.frameRate(for: .matchSource, source: .fps30NTSC) == .fps30NTSC)
    }

    @Test("The balanced preset resolves a 4K source completely")
    func balancedPresetResolvesFourK() throws {
        let source = try SourceCapabilities(
            container: .mp4,
            video: Self.track(3840, 2160),
            audio: nil
        )
        let configuration = try #require(CompressionPreset.balanced1080p.resolve(for: source))

        #expect(configuration.container == .mp4)
        #expect(configuration.video.codec == .h264)
        #expect(configuration.video.resolution.width == 1920)
        #expect(configuration.video.frameRate == .fps30)
        #expect(configuration.audio != .removed)
    }
}

extension CompressionPresetTests {
    static func dimensions(_ width: Int, _ height: Int) throws -> PixelDimensions {
        try #require(PixelDimensions(width: width, height: height))
    }

    static func track(
        _ width: Int,
        _ height: Int,
        rotation: Rotation = .upright
    ) throws -> SourceVideoTrack {
        try SourceVideoTrack(
            codec: .h264,
            dimensions: dimensions(width, height),
            frameRate: .fps30,
            dynamicRange: .sdr,
            rotation: rotation
        )
    }
}
