import Foundation
import Testing
@testable import MiniinKit

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

enum TestFixtures {
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
            url: URL(filePath: "/tmp/clip.mp4"),
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
