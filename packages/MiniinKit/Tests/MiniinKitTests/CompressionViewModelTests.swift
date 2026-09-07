import Foundation
import Testing
@testable import MiniinCore
@testable import MiniinEngines
@testable import MiniinFeatures

@MainActor
@Suite("Compression view model")
struct CompressionViewModelTests {
    @Test("Selecting a readable source produces a ready draft with an estimate")
    func selectingAReadableSourceProducesAReadyDraft() async throws {
        let model = try Self.model()

        await model.select(URL(filePath: "/tmp/clip.mp4"))

        guard case let .ready(draft) = model.state else {
            Issue.record("expected ready, got \(model.state)")
            return
        }

        #expect(draft.configuration.video.resolution.width == 1920)
        #expect(draft.estimate != nil)
        #expect(draft.incompatibility == nil)
    }

    @Test("Selecting an unreadable source reports a typed failure")
    func selectingAnUnreadableSourceReportsATypedFailure() async {
        let model = CompressionViewModel(
            inspection: FakeInspection(media: nil),
            files: FakeFileAccess(spaceFailure: nil),
            queue: ExportQueueModel(queue: ExportQueue(service: TestFixtures.service())),
            device: TestFixtures.device()
        )

        await model.select(URL(filePath: "/tmp/clip.mp4"))

        #expect(model.state == .inspectionFailed(.corruptedMedia))
    }

    @Test("A source no engine can read keeps its reason")
    func aSourceNoEngineCanReadKeepsItsReason() async throws {
        let model = try Self.model(
            media: TestFixtures.media(videoCodec: SourceVideoCodec("theora"))
        )

        await model.select(URL(filePath: "/tmp/clip.mp4"))

        guard case let .ready(draft) = model.state else {
            Issue.record("expected ready, got \(model.state)")
            return
        }

        #expect(draft.incompatibility == .sourceVideoCodecUnreadable(SourceVideoCodec("theora")))
    }

    @Test("Insufficient space fails before anything is submitted")
    func insufficientSpaceFailsBeforeSubmitting() async throws {
        let queue = ExportQueueModel(queue: ExportQueue(service: TestFixtures.service()))
        let model = try Self.model(
            queue: queue,
            files: FakeFileAccess(
                spaceFailure: .insufficientStorage(requiredBytes: 1, availableBytes: 0)
            )
        )

        await model.select(URL(filePath: "/tmp/clip.mp4"))
        await model.startExport(to: URL(filePath: "/tmp/out.mp4"))

        guard case let .exportFailed(_, error) = model.state else {
            Issue.record("expected exportFailed, got \(model.state)")
            return
        }

        #expect(error == .insufficientStorage(requiredBytes: 1, availableBytes: 0))
        #expect(queue.jobs.isEmpty)
    }

    @Test("A successful export promotes the file and reports the reduction")
    func aSuccessfulExportPromotesAndReports() async throws {
        let queue = ExportQueueModel(queue: ExportQueue(service: TestFixtures.service()))
        let observation = Task { await queue.observe() }
        defer { observation.cancel() }

        let model = try Self.model(queue: queue)
        let destination = URL(filePath: "/tmp/final.mp4")

        await model.select(URL(filePath: "/tmp/clip.mp4"))
        await model.startExport(to: destination)

        guard case let .completed(_, result) = model.state else {
            Issue.record("expected completed, got \(model.state)")
            return
        }

        #expect(result.outputURL == destination)
        #expect(result.outputBytes == 5_000_000)
        #expect(result.originalBytes == 200_000_000)
        #expect(result.reductionFraction > 0.9)
    }

    @Test("Cancelling keeps the draft")
    func cancellingKeepsTheDraft() async throws {
        let queue = ExportQueueModel(
            queue: ExportQueue(service: TestFixtures.service(delay: .milliseconds(120)))
        )
        let observation = Task { await queue.observe() }
        defer { observation.cancel() }

        let model = try Self.model(queue: queue)

        await model.select(URL(filePath: "/tmp/clip.mp4"))

        guard case let .ready(before) = model.state else {
            Issue.record("expected ready, got \(model.state)")
            return
        }

        let export = Task { await model.startExport(to: URL(filePath: "/tmp/final.mp4")) }

        try await Task.sleep(for: .milliseconds(60))
        await model.cancel()
        await export.value

        #expect(model.state == .ready(before))
    }

    @Test("Changing the preset re-resolves from the same media")
    func changingThePresetReResolves() async throws {
        let smaller = CompressionPreset(
            id: "test.small",
            category: .general,
            entitlement: .free,
            container: .mp4,
            videoCodec: .h264,
            resolution: .longestSideAtMost(640),
            frameRate: .matchSource,
            rateControl: .bitsPerPixel(0.07),
            audio: .removed,
            metadata: .strip
        )
        let model = try Self.model(presets: [.balanced1080p, smaller])

        await model.select(URL(filePath: "/tmp/clip.mp4"))
        model.select(preset: smaller)

        guard case let .ready(draft) = model.state else {
            Issue.record("expected ready, got \(model.state)")
            return
        }

        #expect(draft.configuration.video.resolution.width == 640)
        #expect(draft.preset.id == "test.small")
    }
}

extension CompressionViewModelTests {
    static func model(
        media: InspectedMedia? = nil,
        queue: ExportQueueModel? = nil,
        files: FakeFileAccess = FakeFileAccess(spaceFailure: nil),
        presets: [CompressionPreset] = [.balanced1080p]
    ) throws -> CompressionViewModel {
        try CompressionViewModel(
            inspection: FakeInspection(media: media ?? TestFixtures.media()),
            files: files,
            queue: queue ?? ExportQueueModel(queue: ExportQueue(service: TestFixtures.service())),
            device: TestFixtures.device(),
            presets: presets
        )
    }
}
