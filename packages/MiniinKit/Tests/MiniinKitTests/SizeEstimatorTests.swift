import MiniinKit
import Testing

@Suite("Size estimator")
struct SizeEstimatorTests {
    @Test("A known configuration produces the expected bounds")
    func knownConfigurationProducesExpectedBounds() throws {
        let configuration = try Self.configuration()
        let estimate = try #require(
            SizeEstimator.estimate(duration: .seconds(60), configuration: configuration)
        )

        #expect(abs(estimate.lowerBytes - 28_421_280) <= 1)
        #expect(abs(estimate.upperBytes - 34_737_120) <= 1)
    }

    @Test("Removing audio lowers the estimate")
    func removingAudioLowersTheEstimate() throws {
        let withAudio = try #require(
            try SizeEstimator.estimate(duration: .seconds(60), configuration: Self.configuration())
        )
        let withoutAudio = try #require(
            try SizeEstimator.estimate(
                duration: .seconds(60),
                configuration: Self.configuration(audio: .removed)
            )
        )

        #expect(withoutAudio.midpointBytes < withAudio.midpointBytes)
    }

    @Test("Quality based rate control cannot be estimated by formula")
    func qualityRateControlYieldsNil() throws {
        let level = try #require(QualityLevel(percent: 70))
        let configuration = try Self.configuration(rateControl: .constantQuality(level: level))

        #expect(SizeEstimator.estimate(duration: .seconds(60), configuration: configuration) == nil)
    }

    @Test("Doubling the duration doubles the estimate")
    func doublingDurationDoublesTheEstimate() throws {
        let configuration = try Self.configuration()
        let single = try #require(
            SizeEstimator.estimate(duration: .seconds(30), configuration: configuration)
        )
        let doubled = try #require(
            SizeEstimator.estimate(duration: .seconds(60), configuration: configuration)
        )

        #expect(abs(doubled.midpointBytes - single.midpointBytes * 2) <= 2)
    }

    @Test("Inverted bounds are normalised")
    func invertedBoundsAreNormalised() {
        let estimate = SizeEstimate(lowerBytes: 900, upperBytes: 100)

        #expect(estimate.lowerBytes == 100)
        #expect(estimate.upperBytes == 900)
    }
}

extension SizeEstimatorTests {
    static func configuration(
        rateControl: RateControl? = nil,
        audio: AudioConfiguration? = nil
    ) throws -> ExportConfiguration {
        let resolution = try #require(PixelDimensions(width: 1920, height: 1080))
        let videoBitrate = try #require(Bitrate(bitsPerSecond: 4_000_000))
        let audioBitrate = try #require(Bitrate(bitsPerSecond: 128_000))

        let encodedAudio = AudioConfiguration.encoded(
            settings: AudioSettings(codec: .aac, bitrate: audioBitrate, channels: .stereo)
        )

        return ExportConfiguration(
            container: .mp4,
            video: VideoConfiguration(
                codec: .h264,
                resolution: resolution,
                frameRate: .fps30,
                rateControl: rateControl ?? .averageBitrate(target: videoBitrate),
                dynamicRange: .convertToSDR
            ),
            audio: audio ?? encodedAudio,
            metadata: .strip,
            hardwareAcceleration: .allowSoftwareFallback
        )
    }
}
