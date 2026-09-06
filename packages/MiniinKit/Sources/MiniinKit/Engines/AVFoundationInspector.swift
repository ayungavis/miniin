import AVFoundation
import Foundation

public struct AVFoundationInspector: MediaInspectionService {
    public init() {}

    public func inspect(_ url: URL) async throws(AppError) -> InspectedMedia {
        do {
            return try await Self.load(url)
        } catch let error as AppError {
            throw error
        } catch {
            // tradeoff: all framework failures become corruptedMedia
            throw AppError.corruptedMedia
        }
    }
}

extension AVFoundationInspector {
    fileprivate static func load(_ url: URL) async throws -> InspectedMedia {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw AppError.noVideoTrack
        }
        let duration = try await asset.load(.duration)

        guard duration.isNumeric else {
            throw AppError.corruptedMedia
        }
        let video = try await sourceVideo(videoTrack)
        let videoRate = try await videoTrack.load(.estimatedDataRate)

        var audio: SourceAudioTrack?
        var audioRate: Float = 0

        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            audio = try await sourceAudio(audioTrack)
            audioRate = try await audioTrack.load(.estimatedDataRate)
        }

        return try InspectedMedia(
            capabilities: SourceCapabilities(
                container: AVFoundationMapping.container(for: url),
                video: video,
                audio: audio
            ),
            url: url,
            fileSizeBytes: fileSize(of: url),
            duration: .seconds(duration.seconds),
            videoBitrate: bitrate(from: videoRate),
            audioBitrate: bitrate(from: audioRate)
        )
    }

    static func sourceVideo(_ track: AVAssetTrack) async throws -> SourceVideoTrack {
        let size = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let minFrameDuration = try await track.load(.minFrameDuration)
        let nominalFrameRate = try await track.load(.nominalFrameRate)
        let formats = try await track.load(.formatDescriptions)
        let characteristics = try await track.load(.mediaCharacteristics)

        guard
            let dimensions = PixelDimensions(width: Int(size.width), height: Int(size.height)),
            let frameRate = AVFoundationMapping.frameRate(
                minFrameDuration: minFrameDuration, nominal: nominalFrameRate
            ),
            let subtype = formats.first.map(CMFormatDescriptionGetMediaSubType)
        else {
            throw AppError.corruptedMedia
        }

        return SourceVideoTrack(
            codec: AVFoundationMapping.videoCodec(
                forSubtype: AVFoundationMapping.fourCharacterCode(subtype)
            ), dimensions: dimensions,
            frameRate: frameRate,
            dynamicRange: characteristics.contains(.containsHDRVideo) ? .hdr : .unknown,
            rotation: AVFoundationMapping.rotation(for: transform)
        )
    }

    static func sourceAudio(_ track: AVAssetTrack) async throws -> SourceAudioTrack {
        guard let format = try await track.load(.formatDescriptions).first else {
            throw AppError.corruptedMedia
        }

        let description = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        let channels = Int(description?.pointee.mChannelsPerFrame ?? 1)

        return SourceAudioTrack(
            codec: AVFoundationMapping.audioCodec(
                forSubtype: AVFoundationMapping.fourCharacterCode(
                    CMFormatDescriptionGetMediaSubType(format)
                )
            ),
            channelCount: channels
        )
    }

    static func bitrate(from rate: Float) -> Bitrate? {
        guard rate.isFinite, rate > 0 else { return nil }

        return Bitrate(bitsPerSecond: Int(rate))
    }

    static func fileSize(of url: URL) throws -> Int64 {
        guard let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            throw AppError.corruptedMedia
        }

        return Int64(size)
    }
}
