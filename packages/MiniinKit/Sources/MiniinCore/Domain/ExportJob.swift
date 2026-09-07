import Foundation

public struct ExportJob: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let source: InspectedMedia
    public let configuration: ExportConfiguration
    public let engine: ProcessingEngine
    public let plan: ExportPlan
    public let outputURL: URL
    public let estimate: SizeEstimate?
    public let createdAt: Date

    public private(set) var state: ExportJobState
    public private(set) var startedAt: Date?
    public private(set) var completedAt: Date?

    public init(
        id: UUID = UUID(),
        source: InspectedMedia,
        configuration: ExportConfiguration,
        engine: ProcessingEngine,
        plan: ExportPlan,
        outputURL: URL,
        estimate: SizeEstimate?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.configuration = configuration
        self.engine = engine
        self.plan = plan
        self.outputURL = outputURL
        self.estimate = estimate
        self.createdAt = createdAt

        state = .queued
        startedAt = nil
        completedAt = nil
    }

    public func advanced(to next: ExportJobState, at date: Date) -> ExportJob? {
        guard state.allows(next) else { return nil }

        var job = self
        job.state = next

        if case .preparing = next {
            job.startedAt = date
        }

        if next.isTerminal {
            job.completedAt = date
        }

        return job
    }
}
