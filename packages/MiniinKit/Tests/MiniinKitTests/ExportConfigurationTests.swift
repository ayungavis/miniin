import Foundation
import MiniinCore
import Testing

@Suite("Export configuration")
struct ExportConfigurationTests {
    @Test("Rate control round-trips both strategies")
    func rateControlRoundTrips() throws {
        let bitrate = try #require(Bitrate(bitsPerSecond: 4_000_000))
        let quality = try #require(QualityLevel(percent: kHIDUsage_Button_70))

        let strategies: [RateControl] = [
            .averageBitrate(target: bitrate),
            .constantQuality(level: quality)
        ]

        for strategy in strategies {
            let data = try JSONEncoder().encode(strategy)
            #expect(try JSONDecoder().decode(RateControl.self, from: data) == strategy)
        }
    }

    @Test("Removed audio round-trips")
    func removedAudioRoundTrips() throws {
        let data = try JSONEncoder().encode(AudioConfiguration.removed)

        #expect(try JSONDecoder().decode(AudioConfiguration.self, from: data) == .removed)
    }

    @Test("Scalars reject out-of-range values")
    func scalarsRejectOutOfRange() {
        #expect(Bitrate(bitsPerSecond: 0) == nil)
        #expect(Bitrate(bitsPerSecond: -1) == nil)
        #expect(QualityLevel(percent: -1) == nil)
        #expect(QualityLevel(percent: 101) == nil)
    }

    @Test("Persisted out-of-range scalars fails to decode")
    func persistedScalarsRejectOutOfRange() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([Bitrate].self, from: Data("[0]".utf8))
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([QualityLevel].self, from: Data("[101]".utf8))
        }
    }

    @Test("Encoded configuration carries its version and a bare-number bitrate")
    func encodedShapeIsPinned() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(Self.sampleConfiguration())
        let json = try #require(String(bytes: data, encoding: .utf8))

        #expect(json.contains("\"version\":1"))
        #expect(json.contains("\"averageBitrate\":{\"target\":4000000}"))
    }

    @Test("A configuration with an unknown version fails to decode")
    func unknownVersionIsRejected() throws {
        let data = try JSONEncoder().encode(Self.sampleConfiguration())
        let json = try #require(String(bytes: data, encoding: .utf8))
        let bumped = json.replacingOccurrences(of: "\"version\":1", with: "\"version\":2")

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ExportConfiguration.self, from: Data(bumped.utf8))
        }
    }
}

extension ExportConfigurationTests {
    static func sampleConfiguration() throws -> ExportConfiguration {
        let resolution = try #require(PixelDimensions(width: 1920, height: 1080))
        let videoBitrate = try #require(Bitrate(bitsPerSecond: 4_000_000))
        let audioBitrate = try #require(Bitrate(bitsPerSecond: 128_000))

        return ExportConfiguration(
            container: .mp4,
            video: VideoConfiguration(
                codec: .h264, resolution: resolution, frameRate: .fps30,
                rateControl: .averageBitrate(target: videoBitrate), dynamicRange: .convertToSDR
            ),
            audio: .encoded(
                settings: AudioSettings(codec: .aac, bitrate: audioBitrate, channels: .stereo)
            ),
            metadata: .strip,
            hardwareAcceleration: .allowSoftwareFallback
        )
    }
}
