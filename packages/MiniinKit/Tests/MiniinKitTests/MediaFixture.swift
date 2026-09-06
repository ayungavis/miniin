import AVFoundation
import CoreMedia
import Foundation

enum MediaFixture {
    enum Failure: Error {
        case pixelBufferUnavailable
        case writerFailed
    }

    static func writeVideo(
        to url: URL,
        width: Int = 64,
        height: Int = 64,
        frameCount: Int = 30,
        framesPerSecond: Int32 = 30
    ) async throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)

        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
        )
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )

        writer.add(input)

        guard writer.startWriting() else {
            throw Failure.writerFailed
        }

        writer.startSession(atSourceTime: .zero)

        for frame in 0 ..< frameCount {
            while !input.isReadyForMoreMediaData {
                await Task.yield()
            }

            guard let pool = adaptor.pixelBufferPool else {
                throw Failure.pixelBufferUnavailable
            }

            var buffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)

            guard status == kCVReturnSuccess, let buffer else {
                throw Failure.pixelBufferUnavailable
            }

            _ = adaptor.append(
                buffer,
                withPresentationTime: CMTime(value: Int64(frame), timescale: framesPerSecond)
            )
        }

        input.markAsFinished()
        await writer.finishWriting()

        guard writer.status == .completed else {
            throw Failure.writerFailed
        }
    }
}
