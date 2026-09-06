public enum ExportEvent: Sendable {
    case progress(ExportProgress)
    case finalizing
    case finished(ExportResult)
    case failed(AppError)
}

public protocol VideoCompressionService: Sendable {
    var supportedEngines: Set<ProcessingEngine> { get }

    func export(_ job: ExportJob) -> AsyncStream<ExportEvent>
}
