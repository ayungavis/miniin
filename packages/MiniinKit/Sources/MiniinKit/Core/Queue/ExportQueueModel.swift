import Foundation
import Observation

@MainActor
@Observable
public final class ExportQueueModel {
    public private(set) var jobs: [ExportJob] = []

    private let queue: ExportQueue

    public init(queue: ExportQueue) {
        self.queue = queue
    }

    // tradeoff: a single observer, a second observe() would split updates rather than duplicate them
    public func observe() async {
        for await snapshot in queue.updates {
            jobs = snapshot
        }
    }

    public func submit(_ job: ExportJob) async {
        await queue.submit(job)
    }

    public func cancel(_ id: UUID) async {
        await queue.cancel(id)
    }
}
