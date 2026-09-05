public enum AppError: Error, Sendable, Hashable {
    case incompatibleConfiguration(IncompatibilityReason)
    case corruptedMedia
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
        case .insufficientStorage: "storage.insufficient"
        case .permissionExpired: "permission.expired"
        case .outputExists: "output.exists"
        case .exportInterrupted: "export.interrupted"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .exportInterrupted: true
        case .incompatibleConfiguration, .corruptedMedia, .insufficientStorage,
             .permissionExpired, .outputExists:
            false
        }
    }

    var recovery: RecoveryAction {
        switch self {
        case let .incompatibleConfiguration(reason): reason.recovery
        case .corruptedMedia: .chooseAnotherVideo
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
        case .sourceContainerUnreadable, .sourceVideoCodecUnreadable, .sourceAudioCodecUnreadable:
            .chooseAnotherVideo
        case .hdrNotSupportedByOutputCodec, .hdrNotSupportedByDevice:
            .convertToSDR
        case .hardwareEncoderUnavailable:
            .allowSoftwareEncoding
        }
    }
}
