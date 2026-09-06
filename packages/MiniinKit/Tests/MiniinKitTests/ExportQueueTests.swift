import Foundation
import MiniinKit
import Testing

@Suite("Export queue")
struct ExportQueueTests {
    @Test("A submitted job runs to completion")
    func submittedJobCompletes() async throws {
        let queue = ExportQueue(service: Self.service(), now: { Self.clock })

        try await queue.submit(Self.job())
        let jobs = try await Self.waitForAllTerminal(queue)

        guard case let .completed(result) = jobs[0].state else {
            Issue.record("expected completed, got \(jobs[0].state)")
            return
        }

        #expect(result.outputBytes == 5_000_000)
    }

    @Test("Cancellation ends in cancelled, not completed")
    func cancellationEndsCancelled() async throws {
        let queue = ExportQueue(
            service: Self.service(delay: .milliseconds(80)),
            now: { Self.clock }
        )
        let job = try Self.job()

        await queue.submit(job)
        try await Task.sleep(for: .milliseconds(30))
        await queue.cancel(job.id)

        let jobs = try await Self.waitForAllTerminal(queue)

        #expect(jobs[0].state == .cancelled)
    }

    @Test("A failing service produces a typed failure")
    func failingServiceProducesTypedFailure() async throws {
        let service = Self.service(failure: .exportInterrupted)
        let queue = ExportQueue(service: service, now: { Self.clock })

        try await queue.submit(Self.job())
        let jobs = try await Self.waitForAllTerminal(queue)

        #expect(jobs[0].state == .failed(error: .exportInterrupted))
    }

    @Test("The concurrency limit holds")
    func concurrencyLimitHolds() async throws {
        let queue = ExportQueue(
            service: Self.service(delay: .milliseconds(80)),
            maximumConcurrentExports: 1,
            now: { Self.clock }
        )

        try await queue.submit(Self.job())
        try await queue.submit(Self.job())

        try await Task.sleep(for: .milliseconds(30))
        let inFlight = await queue.snapshot()

        #expect(inFlight.count == 2)
        #expect(inFlight[1].state == .queued)

        _ = try await Self.waitForAllTerminal(queue)
    }

    @Test("A job naming an unavailable engine fails at admission")
    func unavailableEngineFailsAtAdmission() async throws {
        let queue = ExportQueue(service: Self.service(), now: { Self.clock })

        try await queue.submit(Self.job(engine: .ffmpeg))
        let jobs = try await Self.waitForAllTerminal(queue)

        #expect(
            jobs[0].state == .failed(error: .incompatibleConfiguration(.engineUnavailable(.ffmpeg)))
        )
    }

    @Test("Timestamps come from the injected clock")
    func timestampsComeFromTheInjectedClock() async throws {
        let queue = ExportQueue(service: Self.service(), now: { Self.clock })

        try await queue.submit(Self.job())
        let jobs = try await Self.waitForAllTerminal(queue)

        #expect(jobs[0].startedAt == Self.clock)
        #expect(jobs[0].completedAt == Self.clock)
    }
}

struct FakeCompressionService: VideoCompressionService {
    let supportedEngines: Set<ProcessingEngine>
    let events: [ExportEvent]
    let delay: Duration

    func export(_ job: ExportJob) -> AsyncStream<ExportEvent> {
        let (stream, continuation) = AsyncStream<ExportEvent>.makeStream()

        let task = Task {
            for event in events {
                try? await Task.sleep(for: delay)

                if Task.isCancelled {
                    break
                }

                continuation.yield(event)
            }

            continuation.finish()
        }

        continuation.onTermination = { @Sendable _ in task.cancel() }

        return stream
    }
}

extension ExportQueueTests {
    enum WaitFailure: Error {
        case timedOut
    }

    static let clock = Date(timeIntervalSince1970: 1000)

    static func service(
        failure: AppError? = nil,
        delay: Duration = .milliseconds(1)
    ) -> FakeCompressionService {
        let finished = ExportEvent.finished(
            ExportResult(
                outputURL: URL(filePath: "/tmp/out.mp4"),
                outputBytes: 5_000_000,
                processingDuration: .seconds(3)
            )
        )

        return FakeCompressionService(
            supportedEngines: [.avFoundation],
            events: [
                .progress(ExportProgress(fraction: 0.5)),
                .finalizing,
                failure.map(ExportEvent.failed) ?? finished
            ],
            delay: delay
        )
    }

    static func waitForAllTerminal(_ queue: ExportQueue) async throws -> [ExportJob] {
        for _ in 0 ..< 500 {
            let snapshot = await queue.snapshot()

            if !snapshot.isEmpty, snapshot.allSatisfy(\.state.isTerminal) {
                return snapshot
            }

            try await Task.sleep(for: .milliseconds(10))
        }

        throw WaitFailure.timedOut
    }

    static func job(engine: ProcessingEngine = .avFoundation) throws -> ExportJob {
        let dimensions = try #require(PixelDimensions(width: 1920, height: 1080))
        let bitrate = try #require(Bitrate(bitsPerSecond: 4_000_000))

        let media = InspectedMedia(
            capabilities: SourceCapabilities(
                container: .mp4,
                video: SourceVideoTrack(
                    codec: .h264,
                    dimensions: dimensions,
                    frameRate: .fps30,
                    dynamicRange: .sdr,
                    rotation: .upright
                ),
                audio: nil
            ),
            filename: "clip.mp4",
            fileSizeBytes: 10_000_000,
            duration: .seconds(60),
            videoBitrate: bitrate,
            audioBitrate: nil
        )

        return ExportJob(
            source: media,
            configuration: ExportConfiguration(
                container: .mp4,
                video: VideoConfiguration(
                    codec: .h264,
                    resolution: dimensions,
                    frameRate: .fps30,
                    rateControl: .averageBitrate(target: bitrate),
                    dynamicRange: .convertToSDR
                ),
                audio: .removed,
                metadata: .strip,
                hardwareAcceleration: .allowSoftwareFallback
            ),
            engine: engine,
            plan: ExportPlan(videoEncoder: .hardware, requiresToneMapping: false),
            outputURL: URL(filePath: "/tmp/out.mp4"),
            estimate: nil,
            createdAt: clock
        )
    }
}
