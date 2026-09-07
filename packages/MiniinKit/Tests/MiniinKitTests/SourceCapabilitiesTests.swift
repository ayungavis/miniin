import Foundation
import MiniinCore
import Testing

@Suite("Source and device capabilities")
struct SourceCapabilitiesTests {
    @Test("A known identifier encodes as a bare string")
    func identifierEncodesAsBareString() throws {
        let data = try JSONEncoder().encode([SourceVideoCodec.hevc])
        let json = try #require(String(bytes: data, encoding: .utf8))

        #expect(json == "[\"hevc\"]")
    }

    @Test("An unrecognised identifier decodes successfully")
    func unknownIdentifierDecodes() throws {
        let data = Data("[\"theora\"]".utf8)
        let decoded = try JSONDecoder().decode([SourceVideoCodec].self, from: data)

        #expect(decoded == [SourceVideoCodec("theora")])
    }

    @Test("Source capabilities round-trip with and without audio")
    func capabilitiesRoundTrip() throws {
        let samples = try [Self.sample(withAudio: true), Self.sample(withAudio: false)]

        for capabilities in samples {
            let data = try JSONEncoder().encode(capabilities)

            #expect(try JSONDecoder().decode(SourceCapabilities.self, from: data) == capabilities)
        }
    }

    @Test("Rotation raw values are their degrees")
    func rotationRawValuesAreDegrees() {
        #expect(Rotation.allCases.map(\.rawValue) == [0, 90, 180, 270])
    }

    @Test("A quarter turn swaps the display dimensions")
    func quarterTurnSwapsDisplayDimensions() throws {
        let upright = try Self.videoTrack(rotation: .upright)
        let turned = try Self.videoTrack(rotation: .quarterTurn)

        #expect(upright.displayDimensions.width == 1920)
        #expect(upright.displayDimensions.height == 1080)
        #expect(turned.displayDimensions.width == 1080)
        #expect(turned.displayDimensions.height == 1920)
    }

    @Test("Known identifiers are pinned")
    func knownIdentifiersArePinned() {
        #expect(SourceContainer.mkv.identifier == "mkv")
        #expect(SourceVideoCodec.h264.identifier == "h264")
        #expect(SourceVideoCodec.proRes.identifier == "prores")
        #expect(SourceAudioCodec.aac.identifier == "aac")
    }
}

extension SourceCapabilitiesTests {
    static func videoTrack(rotation: Rotation) throws -> SourceVideoTrack {
        let dimensions = try #require(PixelDimensions(width: 1920, height: 1080))

        return SourceVideoTrack(
            codec: .h264,
            dimensions: dimensions,
            frameRate: .fps30,
            dynamicRange: .sdr,
            rotation: rotation
        )
    }

    static func sample(withAudio: Bool) throws -> SourceCapabilities {
        try SourceCapabilities(
            container: .mp4,
            video: videoTrack(rotation: .upright),
            audio: withAudio ? SourceAudioTrack(codec: .aac, channelCount: 2) : nil
        )
    }
}
