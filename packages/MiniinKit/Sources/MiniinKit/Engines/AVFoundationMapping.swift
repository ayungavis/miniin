import CoreGraphics
import CoreMedia
import Foundation

enum AVFoundationMapping {
    static func container(for url: URL) -> SourceContainer {
        // tradeoff: trusts the pat extension, sniff the container header if mislabell
        SourceContainer(url.pathExtension.lowercased())
    }

    static func videoCodec(forSubtype subtype: String) -> SourceVideoCodec {
        switch subtype {
        case "avc1", "avc3": .h264
        case "hvc1", "hev1": .hevc
        case "vp09": .vp9
        case "av01": .av1
        case "mp4v": .mpeg4
        case "apcn", "apch", "apcs", "apco", "ap4h", "ap4x": .proRes
        case let other: SourceVideoCodec(other)
        }
    }

    static func audioCodec(forSubtype subtype: String) -> SourceAudioCodec {
        switch subtype {
        case "aac": .aac
        case "lpcm", "sowt", "twos": .pcm
        case "alac": .alac
        case ".mp3": .mp3
        case "opus": .opus
        case let other: SourceAudioCodec(other)
        }
    }

    static func frameRate(minFrameDuration: CMTime, nominal: Float) -> FrameRate? {
        if minFrameDuration.isValid, minFrameDuration.value > 0 {
            return FrameRate(
                numerator: Int(minFrameDuration.timescale),
                denominator: Int(minFrameDuration.value)
            )
        }

        // tradeoff: whole-number fallback loses NTSC rates, add a nerarest-known-rate table if needed
        return FrameRate(numerator: Int(nominal.rounded()), denominator: 1)
    }

    static func rotation(for transform: CGAffineTransform) -> Rotation {
        let radians = atan2(transform.b, transform.a)
        let degrees = Int((radians * 180 / .pi).rounded())

        return switch ((degrees % 360) + 360) % 360 {
        case 90: .quarterTurn
        case 180: .halfTurn
        case 270: .threeQuarterTurn
        default: .upright
        }
    }

    static func fourCharacterCode(_ value: FourCharCode) -> String {
        let characters = [24, 16, 8, 0].map {
            Character(Unicode.Scalar(UInt8((value >> $0) & 0xFF)))
        }

        return String(characters).trimmingCharacters(in: .whitespaces)
    }
}
