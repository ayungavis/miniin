import AVFoundation
import Foundation

public struct AVFoundationExporter: VideoCompressionService {
    public let supportedEngines: Set<ProcessingEngine> = [.avFoundation]

    public init() {}

    public func export(_ job: ExportJob) -> AsyncStream<ExportEvent> {
        let (stream, continuation) = AsyncStream<ExportEvent>.makeStream()

        let task = Task {
            await Self.run(job, continuation: continuation)
        }

        continuation.onTermination = { @Sendable _ in task.cancel() }

        return stream
    }
}

private extension AVFoundationExporter {
    @concurrent
    static func run(
        _ job: ExportJob, continuation: AsyncStream<ExportEvent>.Continuation
    ) async {
        var completed = false

        do {
            try await encode(job, continuation: continuation)
            completed = true
        } catch {
            if !Task.isCancelled {
                continuation.yield(.failed(error as? AppError ?? .exportInterrupted))
            }
        }

        if !completed {
            try? FileManager.default.removeItem(at: job.outputURL)
        }

        continuation.finish()
    }

    struct Pipeline {
        let reader: AVAssetReader
        let writer: AVAssetWriter
        let videoOutput: AVAssetReaderOutput
        let videoInput: AVAssetWriterInput
        let audio: (output: AVAssetReaderTrackOutput, input: AVAssetWriterInput)?
        let duration: CMTime
    }

    static func encode(
        _ job: ExportJob,
        continuation: AsyncStream<ExportEvent>.Continuation
    ) async throws {
        let clock = ContinuousClock()
        let started = clock.now

        let pipeline = try await makePipeline(for: job)
        let reader = pipeline.reader
        let writer = pipeline.writer

        guard writer.startWriting(), reader.startReading() else {
            throw AppError.exportInterrupted
        }

        writer.startSession(atSourceTime: .zero)

        do {
            try await drain(pipeline, continuation: continuation)
        } catch {
            reader.cancelReading()
            writer.cancelWriting()
            throw error
        }

        continuation.yield(.finalizing)
        await writer.finishWriting()

        guard writer.status == .completed else {
            throw AppError.exportInterrupted
        }

        try continuation.yield(
            .finished(
                ExportResult(
                    outputURL: job.outputURL,
                    outputBytes: fileSize(of: job.outputURL),
                    processingDuration: clock.now - started
                )
            )
        )
    }

    static func makePipeline(for job: ExportJob) async throws -> Pipeline {
        let asset = AVURLAsset(url: job.source.url)
        let duration = try await asset.load(.duration)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw AppError.noVideoTrack
        }

        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(
            outputURL: job.outputURL,
            fileType: fileType(for: job.configuration.container)
        )

        let videoOutput = AVAssetReaderVideoCompositionOutput(
            videoTracks: [videoTrack],
            videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        videoOutput.videoComposition = try await composition(
            for: asset, configuration: job.configuration
        )
        reader.add(videoOutput)

        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: AVFoundationExportSettings.video(for: job.configuration)
        )
        videoInput.expectsMediaDataInRealTime = false
        writer.add(videoInput)

        return try await Pipeline(
            reader: reader,
            writer: writer,
            videoOutput: videoOutput,
            videoInput: videoInput,
            audio: audioPair(for: job, asset: asset, reader: reader, writer: writer),
            duration: duration
        )
    }

    static func drain(
        _ pipeline: Pipeline,
        continuation: AsyncStream<ExportEvent>.Continuation
    ) async throws {
        try await pump(
            from: pipeline.videoOutput,
            to: pipeline.videoInput,
            duration: pipeline.duration,
            progress: continuation
        )

        guard let audio = pipeline.audio else { return }

        try await pump(
            from: audio.output,
            to: audio.input,
            duration: pipeline.duration,
            progress: nil
        )
    }

    static func pump(
        from output: AVAssetReaderOutput,
        to input: AVAssetWriterInput,
        duration: CMTime,
        progress continuation: AsyncStream<ExportEvent>.Continuation?
    ) async throws {
        var throttle = ProgressThrottle()
        let clock = ContinuousClock()

        while true {
            try Task.checkCancellation()

            guard input.isReadyForMoreMediaData else {
                // tradeoff: polling with a short sleep, move to requestMediaDataWhenReady if it shows up in a profile
                try await Task.sleep(for: .milliseconds(5))
                continue
            }

            guard let buffer = output.copyNextSampleBuffer() else {
                input.markAsFinished()
                return
            }

            guard input.append(buffer) else {
                throw AppError.exportInterrupted
            }

            guard let continuation, duration.seconds > 0 else { continue }

            let fraction = CMSampleBufferGetPresentationTimeStamp(buffer).seconds / duration.seconds

            if throttle.shouldEmit(fraction, at: clock.now) {
                continuation.yield(.progress(ExportProgress(fraction: fraction)))
            }
        }
    }

    static func composition(
        for asset: AVAsset,
        configuration: ExportConfiguration
    ) async throws -> AVMutableVideoComposition {
        let composition = try await AVMutableVideoComposition.videoComposition(
            withPropertiesOf: asset
        )

        composition.renderSize = CGSize(
            width: configuration.video.resolution.width,
            height: configuration.video.resolution.height
        )
        composition.frameDuration = CMTime(
            value: CMTimeValue(configuration.video.frameRate.denominator),
            timescale: CMTimeScale(configuration.video.frameRate.numerator)
        )

        return composition
    }

    // tradeoff: video is pumped fully before audio, interleave if the sample layout matters for streaming
    static func audioPair(
        for job: ExportJob,
        asset: AVAsset,
        reader: AVAssetReader,
        writer: AVAssetWriter
    ) async throws -> (output: AVAssetReaderTrackOutput, input: AVAssetWriterInput)? {
        guard
            let settings = AVFoundationExportSettings.audio(for: job.configuration),
            let track = try await asset.loadTracks(withMediaType: .audio).first
        else {
            return nil
        }

        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM]
        )
        reader.add(output)

        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        writer.add(input)

        return (output, input)
    }

    static func fileType(for container: OutputContainer) -> AVFileType {
        switch container {
        case .mp4: .mp4
        case .mov: .mov
        }
    }

    static func fileSize(of url: URL) throws -> Int64 {
        guard let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            throw AppError.exportInterrupted
        }

        return Int64(size)
    }
}
