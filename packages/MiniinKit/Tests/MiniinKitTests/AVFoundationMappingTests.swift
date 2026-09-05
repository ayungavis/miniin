import CoreGraphics
import CoreMedia
import Foundation
import Testing
@testable import MiniinKit

@Suite("AVFoundation mapping")
struct AVFoundationMappingTests {
    @Test("Each quarter turn maps to its rotation")
    func quarterTurnsMapToRotations() {
        #expect(AVFoundationMapping.rotation(for: .identity) == .upright)
        #expect(AVFoundationMapping.rotation(for: Self.transform(degrees: 90)) == .quarterTurn)
        #expect(AVFoundationMapping.rotation(for: Self.transform(degrees: 180)) == .halfTurn)
        #expect(
            AVFoundationMapping.rotation(for: Self.transform(degrees: 270)) == .threeQuarterTurn
        )
    }

    @Test("An NTSC frame duration keeps its exact ratio")
    func ntscFrameDurationIsExact() {
        let duration = CMTime(value: 1001, timescale: 30000)
        let rate = AVFoundationMapping.frameRate(minFrameDuration: duration, nominal: 29.97)

        #expect(rate == .fps30NTSC)
    }

    @Test("An invalid frame duration falls back to the nominal rate")
    func invalidFrameDurationFallsBack() {
        #expect(AVFoundationMapping.frameRate(minFrameDuration: .invalid, nominal: 30) == .fps30)
    }

    @Test("Known video subtypes map to constants and unknown ones keep their code")
    func videoSubtypesMap() {
        #expect(AVFoundationMapping.videoCodec(forSubtype: "avc1") == .h264)
        #expect(AVFoundationMapping.videoCodec(forSubtype: "hvc1") == .hevc)
        #expect(AVFoundationMapping.videoCodec(forSubtype: "vp09") == .vp9)
        #expect(AVFoundationMapping.videoCodec(forSubtype: "av01") == .av1)
        #expect(AVFoundationMapping.videoCodec(forSubtype: "apcn") == .proRes)
        #expect(AVFoundationMapping.videoCodec(forSubtype: "xvid") == SourceVideoCodec("xvid"))
    }

    @Test("Known audio subtypes map to constants and unknown ones keep their code")
    func audioSubtypesMap() {
        #expect(AVFoundationMapping.audioCodec(forSubtype: "aac") == .aac)
        #expect(AVFoundationMapping.audioCodec(forSubtype: "lpcm") == .pcm)
        #expect(AVFoundationMapping.audioCodec(forSubtype: ".mp3") == .mp3)
        #expect(AVFoundationMapping.audioCodec(forSubtype: "samr") == SourceAudioCodec("samr"))
    }

    @Test("A four character code becomes a trimmed string")
    func fourCharacterCodeBecomesString() {
        #expect(AVFoundationMapping.fourCharacterCode(0x6176_6331) == "avc1")
        #expect(AVFoundationMapping.fourCharacterCode(0x6161_6320) == "aac")
    }

    @Test("Container identifiers are lowercased")
    func containerIdentifiersAreLowercased() {
        #expect(AVFoundationMapping.container(for: URL(filePath: "/tmp/Clip.MP4")) == .mp4)
        #expect(AVFoundationMapping.container(for: URL(filePath: "/tmp/clip.mp4")) == .mp4)
    }
}

extension AVFoundationMappingTests {
    static func transform(degrees: Double) -> CGAffineTransform {
        CGAffineTransform(rotationAngle: degrees * .pi / 180)
    }
}
