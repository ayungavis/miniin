public enum AppError: Error, Sendable, Hashable {
    case incompatibleConfiguration(IncompatibilityReason)
    case corruptedMedia
    case noVideoTrack
    case insufficientStorage(requiredBytes: Int64, availableBytes: Int64)
    case permissionExpired
    case outputExists
    case exportInterrupted
}

public extension AppError {
    var code: String {
        switch self {
        case .incompatibleConfiguration: "configuration.incompatible"
        case .corruptedMedia: "media.corrupted"
        case .noVideoTrack: "media.noVideoTrack"
        case .insufficientStorage: "storage.insufficient"
        case .permissionExpired: "permission.expired"
        case .outputExists: "output.exists"
        case .exportInterrupted: "export.interrupted"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .exportInterrupted: true
        case .incompatibleConfiguration, .corruptedMedia, .noVideoTrack,
             .insufficientStorage, .permissionExpired, .outputExists:
            false
        }
    }

    var recovery: RecoveryAction {
        switch self {
        case let .incompatibleConfiguration(reason): reason.recovery
        case .corruptedMedia, .noVideoTrack: .chooseAnotherVideo
        case .insufficientStorage: .freeUpStorage
        case .permissionExpired: .reauthorizeDestination
        case .outputExists: .resolveNameConflict
        case .exportInterrupted: .retryExport
        }
    }
}

private extension IncompatibilityReason {
    var recovery: RecoveryAction {
        switch self {
        case .sourceContainerUnreadable, .sourceVideoCodecUnreadable, .sourceAudioCodecUnreadable,
             .engineUnavailable:
            .chooseAnotherVideo
        case .hdrNotSupportedByOutputCodec, .hdrNotSupportedByDevice:
            .convertToSDR
        case .hardwareEncoderUnavailable:
            .allowSoftwareEncoding
        }
    }
}
