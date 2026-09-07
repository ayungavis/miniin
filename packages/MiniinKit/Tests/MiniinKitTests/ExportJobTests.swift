import Foundation
import MiniinCore
import Testing

@Suite("Export job")
struct ExportJobTests {
    @Test("The happy path is legal end to end")
    func happyPathIsLegal() throws {
        let job = try Self.job()

        let preparing = try #require(job.advanced(to: .preparing, at: Self.clock))
        let exporting = try #require(preparing.advanced(to: Self.progress(0.5), at: Self.clock))
        let finalizing = try #require(exporting.advanced(to: .finalizing, at: Self.clock))
        let completed = try #require(
            finalizing.advanced(to: .completed(result: Self.result()), at: Self.clock)
        )

        #expect(completed.state.isTerminal)
    }

    @Test("Terminal states allow nothing")
    func terminalStatesAllowNothing() {
        let terminal: [ExportJobState] = [
            .completed(result: Self.result()),
            .cancelled,
            .failed(error: .exportInterrupted)
        ]
        let everything: [ExportJobState] = [
            .queued, .preparing, Self.progress(0), .finalizing, .cancelled
        ]

        for from in terminal {
            #expect(from.isTerminal)

            for to in everything {
                #expect(!from.allows(to))
            }
        }
    }

    @Test("Skipping a state is rejected")
    func skippingAStateIsRejected() throws {
        let job = try Self.job()

        #expect(job.advanced(to: .completed(result: Self.result()), at: Self.clock) == nil)
        #expect(job.advanced(to: .finalizing, at: Self.clock) == nil)
    }

    @Test("Progress cannot go backwards")
    func progressCannotGoBackwards() {
        #expect(Self.progress(0.5).allows(Self.progress(0.75)))
        #expect(Self.progress(0.5).allows(Self.progress(0.5)))
        #expect(!Self.progress(0.5).allows(Self.progress(0.25)))

        #expect(ExportProgress(fraction: 1.5).fraction == 1)
        #expect(ExportProgress(fraction: -1).fraction == 0)
    }

    @Test("Cancellation is legal from every non-terminal state")
    func cancellationIsLegalFromEveryNonTerminalState() {
        let states: [ExportJobState] = [.queued, .preparing, Self.progress(0.5), .finalizing]

        for state in states {
            #expect(state.allows(.cancelled))
        }
    }

    @Test("Timestamps land on the right transitions")
    func timestampsLandOnTheRightTransitions() throws {
        let start = Date(timeIntervalSince1970: 100)
        let end = Date(timeIntervalSince1970: 200)
        let job = try Self.job()

        #expect(job.startedAt == nil)
        #expect(job.completedAt == nil)

        let preparing = try #require(job.advanced(to: .preparing, at: start))

        #expect(preparing.startedAt == start)
        #expect(preparing.completedAt == nil)

        let cancelled = try #require(preparing.advanced(to: .cancelled, at: end))

        #expect(cancelled.startedAt == start)
        #expect(cancelled.completedAt == end)
    }
}

extension ExportJobTests {
    static let clock = Date(timeIntervalSince1970: 0)

    static func progress(_ fraction: Double) -> ExportJobState {
        .exporting(progress: ExportProgress(fraction: fraction))
    }

    static func result() -> ExportResult {
        ExportResult(
            outputURL: URL(filePath: "/tmp/out.mp4"),
            outputBytes: 5_000_000,
            processingDuration: .seconds(12)
        )
    }

    static func job() throws -> ExportJob {
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
            engine: .avFoundation,
            plan: ExportPlan(videoEncoder: .hardware, requiresToneMapping: false),
            outputURL: URL(filePath: "/tmp/out.mp4"),
            estimate: nil,
            createdAt: clock
        )
    }
}
