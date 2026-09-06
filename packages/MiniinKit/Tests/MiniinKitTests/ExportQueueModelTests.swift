import Foundation
import Testing
@testable import MiniinKit

@MainActor
@Suite("Export queue model")
struct ExportQueueModelTests {
    @Test("Jobs are empty before observation starts")
    func jobsAreEmptyBeforeObservationStarts() {
        let model = ExportQueueModel(queue: ExportQueue(service: TestFixtures.service()))

        #expect(model.jobs.isEmpty)
    }

    @Test("Observing publishes a submitted job")
    func observingPublishesASubmittedJob() async throws {
        let queue = ExportQueue(service: TestFixtures.service(delay: .milliseconds(40)))
        let model = ExportQueueModel(queue: queue)
        let observation = Task { await model.observe() }
        defer { observation.cancel() }

        try await model.submit(TestFixtures.job())
        let jobs = try await Self.waitForJobs(model)

        #expect(jobs.count == 1)
    }

    @Test("A completed job arrives with its result")
    func completedJobArrivesWithItsResult() async throws {
        let model = ExportQueueModel(queue: ExportQueue(service: TestFixtures.service()))
        let observation = Task { await model.observe() }
        defer { observation.cancel() }

        try await model.submit(TestFixtures.job())
        let jobs = try await Self.waitForTerminal(model)

        guard case let .completed(result) = jobs[0].state else {
            Issue.record("expected completed, got \(jobs[0].state)")
            return
        }

        #expect(result.outputBytes == 5_000_000)
    }

    @Test("Cancelling reaches the queue")
    func cancellingReachesTheQueue() async throws {
        let queue = ExportQueue(service: TestFixtures.service(delay: .milliseconds(80)))
        let model = ExportQueueModel(queue: queue)
        let observation = Task { await model.observe() }
        defer { observation.cancel() }

        let job = try TestFixtures.job()
        await model.submit(job)

        try await Task.sleep(for: .milliseconds(30))
        await model.cancel(job.id)

        let jobs = try await Self.waitForTerminal(model)

        #expect(jobs[0].state == .cancelled)
    }
}

extension ExportQueueModelTests {
    enum WaitFailure: Error {
        case timedOut
    }

    static func waitForJobs(_ model: ExportQueueModel) async throws -> [ExportJob] {
        try await wait(model) { !$0.isEmpty }
    }

    static func waitForTerminal(_ model: ExportQueueModel) async throws -> [ExportJob] {
        try await wait(model) { !$0.isEmpty && $0.allSatisfy(\.state.isTerminal) }
    }

    static func wait(
        _ model: ExportQueueModel,
        until condition: ([ExportJob]) -> Bool
    ) async throws -> [ExportJob] {
        for _ in 0 ..< 500 {
            if condition(model.jobs) {
                return model.jobs
            }

            try await Task.sleep(for: .milliseconds(10))
        }

        throw WaitFailure.timedOut
    }
}
