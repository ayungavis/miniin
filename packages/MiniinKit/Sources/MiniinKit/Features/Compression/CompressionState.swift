import Foundation

public struct CompressionDraft: Sendable, Equatable {
    public let media: InspectedMedia
    public let preset: CompressionPreset
    public let configuration: ExportConfiguration
    public let selection: EngineSelection
    public let estimate: SizeEstimate?

    public var incompatibility: IncompatibilityReason? {
        guard case let .unsupported(reason) = selection else { return nil }

        return reason
    }

    public var defaultDestination: URL {
        URL.documentsDirectory
            .appending(path: media.url.deletingPathExtension().lastPathComponent)
            .appendingPathExtension(configuration.container.fileExtension)
    }
}

public struct CompressionResult: Sendable, Equatable {
    public let outputURL: URL
    public let outputBytes: Int64
    public let originalBytes: Int64
    public let processingDuration: Duration

    public var reductionBytes: Int64 {
        max(0, originalBytes - outputBytes)
    }

    public var reductionFraction: Double {
        guard originalBytes > 0 else { return 0 }

        return Double(reductionBytes) / Double(originalBytes)
    }
}

public enum CompressionState: Sendable, Equatable {
    case empty
    case inspecting
    case ready(CompressionDraft)
    case exporting(ExportJob)
    case completed(CompressionDraft, CompressionResult)
    case exportFailed(CompressionDraft, AppError)
    case inspectionFailed(AppError)
}

public extension CompressionState {
    var editableDraft: CompressionDraft? {
        switch self {
        case let .ready(draft), let .exportFailed(draft, _): draft
        case .empty, .inspecting, .exporting, .completed, .inspectionFailed: nil
        }
    }
}
