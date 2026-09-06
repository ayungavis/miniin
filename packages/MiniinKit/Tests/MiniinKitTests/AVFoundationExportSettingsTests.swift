import AVFoundation
import Foundation
import Testing
@testable import MiniinKit

@Suite("AVFoundation export settings")
struct AVFoundationExportSettingsTests {
    @Test("Video settings carry the codec and dimensions")
    func videoSettingsCarryCodecAndDimensions() throws {
        let settings = try AVFoundationExportSettings.video(for: Self.configuration())

        #expect(settings[AVVideoCodecKey] as? AVVideoCodecType == .h264)
        #expect(settings[AVVideoWidthKey] as? Int == 1920)
        #expect(settings[AVVideoHeightKey] as? Int == 1080)
    }

    @Test("An average bitrate produces a bitrate key and no quality key")
    func averageBitrateProducesBitrateKeyOnly() throws {
        let configuration = try Self.configuration()
        let properties = AVFoundationExportSettings.compressionProperties(for: configuration.video)

        #expect(properties[AVVideoAverageBitRateKey] as? Int == 4_000_000)
        #expect(properties[AVVideoQualityKey] == nil)
        #expect(properties[AVVideoExpectedSourceFrameRateKey] as? Int == 30)
    }

    @Test("Constant quality produces a quality key and no bitrate key")
    func constantQualityProducesQualityKeyOnly() throws {
        let level = try #require(QualityLevel(percent: 70))
        let configuration = try Self.configuration(rateControl: .constantQuality(level: level))
        let properties = AVFoundationExportSettings.compressionProperties(for: configuration.video)

        #expect(properties[AVVideoQualityKey] as? Double == 0.7)
        #expect(properties[AVVideoAverageBitRateKey] == nil)
    }

    @Test("Removed audio produces no audio settings")
    func removedAudioProducesNoSettings() throws {
        let configuration = try Self.configuration(audio: .removed)

        #expect(AVFoundationExportSettings.audio(for: configuration) == nil)
    }

    @Test("Encoded audio carries the format, channels, and bitrate")
    func encodedAudioCarriesFormatChannelsAndBitrate() throws {
        let settings = try #require(try AVFoundationExportSettings.audio(for: Self.configuration()))

        #expect(settings[AVFormatIDKey] as? AudioFormatID == kAudioFormatMPEG4AAC)
        #expect(settings[AVNumberOfChannelsKey] as? Int == 2)
        #expect(settings[AVEncoderBitRateKey] as? Int == 128_000)
    }
}

extension AVFoundationExportSettingsTests {
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
