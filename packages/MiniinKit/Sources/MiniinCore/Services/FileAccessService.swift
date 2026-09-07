import Foundation

public enum FilenameConflictPolicy: Sendable {
    case keepBoth
    case replace
    case fail
}

public protocol FileAccessService: Sendable {
    func temporaryOutputURL(for configuration: ExportConfiguration) -> URL

    func ensureSpace(forEstimatedBytes bytes: Int64, at url: URL) throws(AppError)

    func promote(
        _ temporary: URL,
        to destination: URL,
        conflict: FilenameConflictPolicy
    ) throws(AppError) -> URL
}
