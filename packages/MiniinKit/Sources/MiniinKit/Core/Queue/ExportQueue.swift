import Foundation

public actor ExportQueue {
    public nonisolated let updates: AsyncStream<[ExportJob]>

    private let service: any VideoCompressionService
    private let maximumConcurrentExports: Int
    private let now: @Sendable () -> Date
    private let continuation: AsyncStream<[ExportJob]>.Continuation

    private var jobs: [UUID: ExportJob] = [:]
    private var order: [UUID] = []
    private var running: [UUID: Task<Void, Never>] = [:]

    public init(
        service: any VideoCompressionService,
        maximumConcurrentExports: Int = 1,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        let (stream, continuation) = AsyncStream<[ExportJob]>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )

        updates = stream
        self.continuation = continuation
        self.service = service
        self.maximumConcurrentExports = maximumConcurrentExports
        self.now = now
    }

    public func submit(_ job: ExportJob) {
        jobs[job.id] = job
        order.append(job.id)

        publish()
        startPending()
    }

    public func cancel(_ id: UUID) {
        if let task = running[id] {
            task.cancel()
            return
        }

        apply(id, .cancelled)
        publish()
        startPending()
    }

    public func snapshot() -> [ExportJob] {
        order.compactMap { jobs[$0] }
    }
}

private extension ExportQueue {
    func publish() {
        continuation.yield(snapshot())
    }

    func apply(_ id: UUID, _ state: ExportJobState) {
        guard let job = jobs[id], let advanced = job.advanced(to: state, at: now()) else { return }

        jobs[id] = advanced
    }

    func startPending() {
        while running.count < maximumConcurrentExports, let id = nextQueued() {
            start(id)
        }
    }

    func nextQueued() -> UUID? {
        order.first { id in
            guard let job = jobs[id], case .queued = job.state else { return false }

            return true
        }
    }

    func start(_ id: UUID) {
        guard let job = jobs[id] else { return }

        apply(id, .preparing)

        guard service.supportedEngines.contains(job.engine) else {
            apply(id, .failed(error: .incompatibleConfiguration(.engineUnavailable(job.engine))))
            publish()
            return
        }

        publish()

        running[id] = Task { [weak self] in
            await self?.run(id, job: job)
        }
    }

    func run(_ id: UUID, job: ExportJob) async {
        for await event in service.export(job) {
            if Task.isCancelled {
                break
            }

            apply(id, state(for: event))
            publish()
        }

        apply(id, Task.isCancelled ? .cancelled : .failed(error: .exportInterrupted))

        running[id] = nil
        publish()
        startPending()
    }

    func state(for event: ExportEvent) -> ExportJobState {
        switch event {
        case let .progress(progress): .exporting(progress: progress)
        case .finalizing: .finalizing
        case let .finished(result): .completed(result: result)
        case let .failed(error): .failed(error: error)
        }
    }
}
