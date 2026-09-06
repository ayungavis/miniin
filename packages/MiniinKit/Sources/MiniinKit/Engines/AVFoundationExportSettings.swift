import AVFoundation
import Foundation

enum AVFoundationExportSettings {
    // swiftlint:disable:next no_untyped_dictionary_api
    static func video(for configuration: ExportConfiguration) -> [String: Any] {
        let video = configuration.video

        return [
            AVVideoCodecKey: codecType(for: video.codec),
            AVVideoWidthKey: video.resolution.width,
            AVVideoHeightKey: video.resolution.height,
            AVVideoCompressionPropertiesKey: compressionProperties(for: video)
        ]
    }

    // swiftlint:disable:next no_untyped_dictionary_api
    static func audio(for configuration: ExportConfiguration) -> [String: Any]? {
        guard case let .encoded(settings) = configuration.audio else { return nil }

        return [
            AVFormatIDKey: formatID(for: settings.codec),
            // tradeoff: 48 kHz until the pump can pass the source sample rate through
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: channelCount(for: settings.channels),
            AVEncoderBitRateKey: settings.bitrate.bitsPerSecond
        ]
    }

    // swiftlint:disable:next no_untyped_dictionary_api
    static func compressionProperties(for video: VideoConfiguration) -> [String: Any] {
        let expectedFrameRate = Int(video.frameRate.value.rounded())

        return switch video.rateControl {
        case let .averageBitrate(target):
            [
                AVVideoExpectedSourceFrameRateKey: expectedFrameRate,
                AVVideoAverageBitRateKey: target.bitsPerSecond
            ]
        case let .constantQuality(level):
            [
                AVVideoExpectedSourceFrameRateKey: expectedFrameRate,
                AVVideoQualityKey: Double(level.percent) / 100
            ]
        }
    }

    static func codecType(for codec: OutputVideoCodec) -> AVVideoCodecType {
        switch codec {
        case .h264: .h264
        case .hevc: .hevc
        }
    }

    static func formatID(for codec: OutputAudioCodec) -> AudioFormatID {
        switch codec {
        case .aac: kAudioFormatMPEG4AAC
        }
    }

    static func channelCount(for channels: AudioChannels) -> Int {
        switch channels {
        case .mono: 1
        case .stereo: 2
        }
    }
}
