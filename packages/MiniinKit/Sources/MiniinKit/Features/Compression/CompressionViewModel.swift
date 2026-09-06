import Foundation
import Observation

@MainActor
@Observable
public final class CompressionViewModel {
    public private(set) var state: CompressionState = .empty

    public let presets: [CompressionPreset]

    private let inspection: any MediaInspectionService
    private let files: any FileAccessService
    private let queue: ExportQueueModel
    private let router: EngineRouter
    private let device: DeviceCapabilities

    public init(
        inspection: any MediaInspectionService,
        files: any FileAccessService,
        queue: ExportQueueModel,
        device: DeviceCapabilities,
        router: EngineRouter = EngineRouter(),
        presets: [CompressionPreset] = [.balanced1080p]
    ) {
        self.inspection = inspection
        self.files = files
        self.queue = queue
        self.device = device
        self.router = router
        self.presets = presets
    }

    public func select(_ url: URL) async {
        state = .inspecting

        do {
            let media = try await inspection.inspect(url)

            guard let preset = presets.first, let draft = draft(for: media, preset: preset) else {
                state = .inspectionFailed(.corruptedMedia)
                return
            }

            state = .ready(draft)
        } catch {
            state = .inspectionFailed(error)
        }
    }

    public func select(preset: CompressionPreset) {
        guard case let .ready(current) = state,
              let updated = draft(for: current.media, preset: preset)
        else {
            return
        }

        state = .ready(updated)
    }

    public func startExport(to destination: URL) async {
        guard case let .ready(draft) = state,
              draft.incompatibility == nil,
              let routed = routed(draft.selection)
        else {
            return
        }

        let staged = files.temporaryOutputURL(for: draft.configuration)

        do {
            try files.ensureSpace(forEstimatedBytes: requiredBytes(for: draft), at: destination)
        } catch {
            state = .exportFailed(draft, error)
            return
        }

        let job = ExportJob(
            source: draft.media,
            configuration: draft.configuration,
            engine: routed.engine,
            plan: routed.plan,
            outputURL: staged,
            estimate: draft.estimate,
            createdAt: Date()
        )

        state = .exporting(job)
        await queue.submit(job)
        await settle(job, draft: draft, destination: destination)
    }

    public func cancel() async {
        guard case let .exporting(job) = state else { return }

        await queue.cancel(job.id)
    }
}

private extension CompressionViewModel {
    func draft(for media: InspectedMedia, preset: CompressionPreset)
        -> CompressionDraft?
    {
        guard let configuration = preset.resolve(for: media.capabilities) else { return nil }

        return CompressionDraft(
            media: media,
            preset: preset,
            configuration: configuration,
            selection: router.route(
                source: media.capabilities,
                device: device,
                configuration: configuration
            ),
            estimate: SizeEstimator.estimate(
                duration: media.duration,
                configuration: configuration
            )
        )
    }

    func routed(_ selection: EngineSelection) -> (
        engine: ProcessingEngine, plan: ExportPlan
    )? {
        switch selection {
        case let .avFoundation(plan): (.avFoundation, plan)
        case let .ffmpeg(plan): (.ffmpeg, plan)
        case .unsupported: nil
        }
    }

    func requiredBytes(for draft: CompressionDraft) -> Int64 {
        draft.estimate?.upperBytes ?? draft.media.fileSizeBytes
    }

    func settle(_ job: ExportJob, draft: CompressionDraft, destination: URL) async {
        guard let terminal = await awaitTerminal(job.id) else {
            state = .ready(draft)
            return
        }

        switch terminal.state {
        case let .completed(result):
            promote(result, draft: draft, destination: destination)

        case let .failed(error):
            state = .exportFailed(draft, error)

        default:
            state = .ready(draft)
        }
    }

    func promote(_ result: ExportResult, draft: CompressionDraft, destination: URL) {
        do {
            let final = try files.promote(result.outputURL, to: destination, conflict: .keepBoth)

            state = .completed(
                draft,
                CompressionResult(
                    outputURL: final,
                    outputBytes: result.outputBytes,
                    originalBytes: draft.media.fileSizeBytes,
                    processingDuration: result.processingDuration
                )
            )
        } catch {
            state = .exportFailed(draft, error)
        }
    }

    // tradeoff: polls the observed snapshot, replace with a continuation-based await on the actor if the latency matters
    func awaitTerminal(_ id: UUID) async -> ExportJob? {
        while !Task.isCancelled {
            guard let job = queue.jobs.first(where: { $0.id == id }) else {
                try? await Task.sleep(for: .milliseconds(50))
                continue
            }

            if job.state.isTerminal {
                return job
            }

            state = .exporting(job)

            try? await Task.sleep(for: .milliseconds(50))
        }

        return nil
    }
}
