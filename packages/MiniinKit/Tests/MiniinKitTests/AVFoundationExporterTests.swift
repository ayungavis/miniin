import Foundation
import Testing
@testable import MiniinKit

@Suite("AVFoundation exporter")
struct AVFoundationExporterTests {
    private let exporter = AVFoundationExporter()

    @Test("A generated clip encodes to a real file")
    func generatedClipEncodesToARealFile() async throws {
        let source = Self.temporaryURL()
        let output = Self.temporaryURL()
        defer { Self.remove(source, output) }

        try await MediaFixture.writeVideo(to: source)
        let events = try await Self.collect(exporter.export(Self.job(source, output)))

        guard case let .finished(result) = events.last else {
            Issue.record("expected finished, got \(String(describing: events.last))")
            return
        }

        #expect(result.outputBytes > 0)
        #expect(FileManager.default.fileExists(atPath: output.path()))
    }

    @Test("The output inspects back as the configured format")
    func outputInspectsBackAsConfigured() async throws {
        let source = Self.temporaryURL()
        let output = Self.temporaryURL()
        defer { Self.remove(source, output) }

        try await MediaFixture.writeVideo(to: source)
        _ = try await Self.collect(exporter.export(Self.job(source, output)))

        let media = try await AVFoundationInspector().inspect(output)

        #expect(media.capabilities.container == .mp4)
        #expect(media.capabilities.video.codec == .h264)
        #expect(media.capabilities.video.dimensions.width == 64)
        #expect(media.capabilities.video.dimensions.height == 64)
    }

    @Test("Progress is non-decreasing")
    func progressIsNonDecreasing() async throws {
        let source = Self.temporaryURL()
        let output = Self.temporaryURL()
        defer { Self.remove(source, output) }

        try await MediaFixture.writeVideo(to: source, frameCount: 120)
        let events = try await Self.collect(exporter.export(Self.job(source, output)))

        let fractions = events.compactMap { event -> Double? in
            guard case let .progress(progress) = event else { return nil }

            return progress.fraction
        }

        #expect(!fractions.isEmpty)
        #expect(fractions == fractions.sorted())
    }

    @Test("Cancelling mid-export yields no finished event and leaves no file")
    func cancellingLeavesNothingBehind() async throws {
        let source = Self.temporaryURL()
        let output = Self.temporaryURL()
        defer { Self.remove(source, output) }

        try await MediaFixture.writeVideo(to: source, width: 640, height: 480, frameCount: 600)
        let job = try await Self.job(source, output, width: 640, height: 480)
        let task = Task { await Self.collect(exporter.export(job)) }

        try await Task.sleep(for: .milliseconds(80))
        task.cancel()

        let events = await task.value
        let removed = try await Self.waitForRemoval(of: output)

        #expect(!events.contains {
            if case .finished = $0 {
                true
            } else {
                false
            }
        })
        #expect(removed)
    }

    @Test("A source that disappeared yields a failure")
    func vanishedSourceYieldsFailure() async throws {
        let source = Self.temporaryURL()
        let output = Self.temporaryURL()
        defer { Self.remove(source, output) }

        try await MediaFixture.writeVideo(to: source)
        let job = try await Self.job(source, output)
        try FileManager.default.removeItem(at: source)

        let events = await Self.collect(exporter.export(job))

        #expect(events.contains {
            if case .failed = $0 {
                true
            } else {
                false
            }
        })
    }
}

extension AVFoundationExporterTests {
    static func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("mp4")
    }

    static func remove(_ urls: URL...) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }

    static func waitForRemoval(of url: URL) async throws -> Bool {
        for _ in 0 ..< 200 {
            if !FileManager.default.fileExists(atPath: url.path()) {
                return true
            }

            try await Task.sleep(for: .milliseconds(10))
        }

        return false
    }

    static func collect(_ stream: AsyncStream<ExportEvent>) async -> [ExportEvent] {
        var events: [ExportEvent] = []

        for await event in stream {
            events.append(event)
        }

        return events
    }

    static func job(
        _ source: URL,
        _ output: URL,
        width: Int = 64,
        height: Int = 64
    ) async throws -> ExportJob {
        let media = try await AVFoundationInspector().inspect(source)
        let resolution = try #require(PixelDimensions(width: width, height: height))
        let bitrate = try #require(Bitrate(bitsPerSecond: 400_000))

        return ExportJob(
            source: media,
            configuration: ExportConfiguration(
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
            ),
            engine: .avFoundation,
            plan: ExportPlan(videoEncoder: .hardware, requiresToneMapping: false),
            outputURL: output,
            estimate: nil,
            createdAt: Date()
        )
    }
}
