import Foundation

public struct LocalFileAccess: FileAccessService {
    public init() {}

    public func temporaryOutputURL(for configuration: ExportConfiguration) -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension(configuration.container.fileExtension)
    }

    public func ensureSpace(forEstimatedBytes bytes: Int64, at url: URL) throws(AppError) {
        // tradeoff: a volume that will not report capacity is treated as having room, map the late disk-full failure once it can be told apart
        guard let available = Self.availableCapacity(at: url) else { return }

        guard available >= bytes else {
            throw .insufficientStorage(requiredBytes: bytes, availableBytes: available)
        }
    }

    public func promote(
        _ temporary: URL,
        to destination: URL,
        conflict: FilenameConflictPolicy
    ) throws(AppError) -> URL {
        let manager = FileManager.default
        let target = try Self.target(for: destination, conflict: conflict, manager: manager)

        do {
            if manager.fileExists(atPath: target.path()) {
                try manager.removeItem(at: target)
            }

            try manager.moveItem(at: temporary, to: target)
        } catch {
            // tradeoff: every move failure reads as a destination permission problem, refine when security-scoped access lands
            throw AppError.permissionExpired
        }

        return target
    }
}

extension LocalFileAccess {
    static func target(
        for destination: URL,
        conflict: FilenameConflictPolicy,
        manager: FileManager
    ) throws(AppError) -> URL {
        switch conflict {
        case .keepBoth:
            return uniqueURL(for: destination) { manager.fileExists(atPath: $0.path()) }

        case .replace:
            return destination

        case .fail:
            guard !manager.fileExists(atPath: destination.path()) else {
                throw .outputExists
            }

            return destination
        }
    }

    static func uniqueURL(for url: URL, exists: (URL) -> Bool) -> URL {
        guard exists(url) else { return url }

        for index in 2 ... 99 {
            let candidate = suffixed(url, with: "\(index)")

            if !exists(candidate) {
                return candidate
            }
        }

        return suffixed(url, with: UUID().uuidString)
    }

    static func suffixed(_ url: URL, with suffix: String) -> URL {
        let base = url.deletingPathExtension()

        return
            base
                .deletingLastPathComponent()
                .appending(path: "\(base.lastPathComponent) \(suffix)")
                .appendingPathExtension(url.pathExtension)
    }

    static func availableCapacity(at url: URL) -> Int64? {
        let directory = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        let values = try? directory.resourceValues(
            forKeys: [.volumeAvailableCapacityForImportantUsageKey]
        )

        return values?.volumeAvailableCapacityForImportantUsage
    }
}
