import Foundation

public enum ExportJobState: Sendable, Hashable {
    case queued
    case preparing
    case exporting(progress: ExportProgress)
    case finalizing
    case completed(result: ExportResult)
    case cancelled
    case failed(error: AppError)
}

public extension ExportJobState {
    var isTerminal: Bool {
        switch self {
        case .completed, .cancelled, .failed: true
        case .queued, .preparing, .exporting, .finalizing: false
        }
    }

    func allows(_ next: ExportJobState) -> Bool {
        switch (self, next) {
        case (.queued, .preparing),
             (.preparing, .exporting),
             (.exporting, .finalizing),
             (.finalizing, .completed):
            true

        case let (.exporting(current), .exporting(updated)):
            updated.fraction >= current.fraction

        case (.preparing, .failed),
             (.exporting, .failed),
             (.finalizing, .failed):
            true

        case (_, .cancelled):
            !isTerminal

        default:
            false
        }
    }
}

public struct ExportProgress: Sendable, Hashable {
    public let fraction: Double

    public init(fraction: Double) {
        self.fraction = min(max(fraction, 0), 1)
    }
}

public struct ExportResult: Sendable, Hashable {
    public let outputURL: URL
    public let outputBytes: Int64
    public let processingDuration: Duration

    public init(outputURL: URL, outputBytes: Int64, processingDuration: Duration) {
        self.outputURL = outputURL
        self.outputBytes = outputBytes
        self.processingDuration = processingDuration
    }
}
