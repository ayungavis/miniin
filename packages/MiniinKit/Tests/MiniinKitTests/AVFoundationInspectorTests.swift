import Foundation
import Testing
@testable import MiniinKit

@Suite("AVFoundation inspector")
struct AVFoundationInspectorTests {
    private let inspector = AVFoundationInspector()

    @Test("A file that is not media throws a typed error")
    func nonMediaFileThrowsAppError() async throws {
        let url = Self.temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try Data("not a video".utf8).write(to: url)

        await #expect(throws: AppError.self) {
            try await inspector.inspect(url)
        }
    }

    @Test("A missing file throws a typed error")
    func missingFileThrowsAppError() async {
        await #expect(throws: AppError.self) {
            try await inspector.inspect(Self.temporaryURL())
        }
    }

    @Test("A generated clip inspects to its own properties")
    func generatedClipInspectsToItsOwnProperties() async throws {
        let url = Self.temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try await MediaFixture.writeVideo(to: url)
        let media = try await inspector.inspect(url)

        #expect(media.capabilities.container == .mp4)
        #expect(media.capabilities.video.codec == .h264)
        #expect(media.capabilities.video.dimensions.width == 64)
        #expect(media.capabilities.video.dimensions.height == 64)
        #expect(media.capabilities.video.frameRate == .fps30)
        #expect(media.capabilities.audio == nil)
        #expect(media.filename == url.lastPathComponent)
        #expect(media.fileSizeBytes > 0)
    }

    @Test("A generated clip routes to AVFoundation")
    func generatedClipRoutesToAVFoundation() async throws {
        let url = Self.temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try await MediaFixture.writeVideo(to: url)
        let media = try await inspector.inspect(url)

        let selection = try EngineRouter().route(
            source: media.capabilities,
            device: DeviceCapabilities(hardwareVideoEncoders: [.h264], supportsHDRExport: true),
            configuration: Self.configuration()
        )

        guard case .avFoundation = selection else {
            Issue.record("expected AVFoundation, got \(selection)")
            return
        }
    }
}

extension AVFoundationInspectorTests {
    static func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("mp4")
    }

    static func configuration() throws -> ExportConfiguration {
        let resolution = try #require(PixelDimensions(width: 64, height: 64))
        let bitrate = try #require(Bitrate(bitsPerSecond: 1_000_000))

        return ExportConfiguration(
            container: .mp4,
            video: VideoConfiguration(
                codec: .h264,
                resolution: resolution,
                frameRate: .fps30,
                rateControl: .averageBitrate(target: bitrate),
                dynamicRange: .convertToSDR
            ),
            audio: .removed,
            metadata: .strip,
            hardwareAcceleration: .allowSoftwareFallback
        )
    }
}
