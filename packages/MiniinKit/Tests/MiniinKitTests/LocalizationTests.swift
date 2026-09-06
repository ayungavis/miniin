import Foundation
import Testing
@testable import MiniinKit

@Suite("Localization")
struct LocalizationTests {
    @Test("Every error and recovery key has a catalog entry")
    func presentationKeysHaveEntries() throws {
        let catalog = try String(contentsOf: Self.catalog, encoding: .utf8)

        for key in Self.presentationKeys {
            #expect(
                catalog.contains("\"\(key)\""),
                Comment(rawValue: "Localizable.xcstrings has no entry for \(key)")
            )
        }
    }
}

extension LocalizationTests {
    static let catalog = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Sources/MiniinKit/Resources/Localizable.xcstrings")

    static let errors: [AppError] = [
        .corruptedMedia,
        .noVideoTrack,
        .insufficientStorage(requiredBytes: 1, availableBytes: 0),
        .permissionExpired,
        .outputExists,
        .exportInterrupted,
        .incompatibleConfiguration(.hdrNotSupportedByDevice)
    ]

    static let reasons: [IncompatibilityReason] = [
        .sourceContainerUnreadable(.mp4),
        .sourceVideoCodecUnreadable(.h264),
        .sourceAudioCodecUnreadable(.aac),
        .hdrNotSupportedByOutputCodec(.hevc),
        .hdrNotSupportedByDevice,
        .hardwareEncoderUnavailable(.h264),
        .engineUnavailable(.ffmpeg)
    ]

    static var presentationKeys: [String] {
        errors.map { "error.\($0.code)" }
            + reasons.map { "error.\($0.code)" }
            + RecoveryAction.allCases.map { "recovery.\($0.rawValue)" }
    }
}
