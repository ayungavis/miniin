public enum RecoveryAction: String, Sendable, CaseIterable {
    case chooseAnotherVideo
    case convertToSDR
    case allowSoftwareEncoding
    case freeUpStorage
    case reauthorizeDestination
    case resolveNameConflict
    case retryExport
}
