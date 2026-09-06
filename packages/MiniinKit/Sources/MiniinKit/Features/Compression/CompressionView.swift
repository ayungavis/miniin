import SwiftUI
import UniformTypeIdentifiers

public struct CompressionView: View {
    private let model: CompressionViewModel

    @State private var isImporting = false

    public init(model: CompressionViewModel) {
        self.model = model
    }

    public var body: some View {
        content
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
            .tint(AppColor.accent)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.movie],
                onCompletion: handleImport
            )
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .empty:
            empty

        case .inspecting:
            ProgressView { Text("compression.inspecting", bundle: .module) }

        case let .ready(draft):
            ready(draft)

        case let .exporting(job):
            exporting(job)

        case let .completed(draft, result):
            completed(draft, result)

        case let .exportFailed(draft, error):
            exportFailed(draft, error)

        case let .inspectionFailed(error):
            inspectionFailed(error)
        }
    }
}

private extension CompressionView {
    var empty: some View {
        VStack(spacing: Spacing.sm) {
            Text("compression.empty.title", bundle: .module)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.contentPrimary)

            Text("compression.empty.subtitle", bundle: .module)
                .font(AppFont.body)
                .foregroundStyle(AppColor.contentSecondary)
                .multilineTextAlignment(.center)

            chooseButton("compression.choose")
        }
    }

    func ready(_ draft: CompressionDraft) -> some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Text(verbatim: draft.media.filename)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.contentPrimary)

                row("compression.original", value: Self.bytes(draft.media.fileSizeBytes))
                row("compression.format", value: Self.specification(draft.configuration))

                if let estimate = draft.estimate {
                    row("compression.estimate", value: Self.bytes(estimate.upperBytes))
                }
            }

            if let reason = draft.incompatibility {
                failure(.incompatibleConfiguration(reason))
            } else {
                Button {
                    Task { await model.startExport(to: draft.defaultDestination) }
                } label: {
                    Text("compression.export", bundle: .module)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    func exporting(_ job: ExportJob) -> some View {
        VStack(spacing: Spacing.lg) {
            ProgressView(value: Self.fraction(of: job.state)) {
                Text("compression.exporting", bundle: .module)
                    .foregroundStyle(AppColor.contentSecondary)
            }
            .progressViewStyle(.linear)

            Button(role: .cancel) {
                Task { await model.cancel() }
            } label: {
                Text("compression.cancel", bundle: .module)
            }
        }
        .frame(maxWidth: 360)
    }

    func completed(_ draft: CompressionDraft, _ result: CompressionResult) -> some View {
        VStack(spacing: Spacing.sm) {
            Text("compression.done.title", bundle: .module)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.contentPrimary)

            row("compression.original", value: Self.bytes(result.originalBytes))
            row("compression.output", value: Self.bytes(result.outputBytes))
            row("compression.reduction", value: Self.reduction(result))
            row("compression.format", value: Self.specification(draft.configuration))
            row("compression.duration", value: Self.elapsed(result.processingDuration))

            chooseButton("compression.choose.another")
        }
        .frame(maxWidth: 360)
    }

    func exportFailed(_ draft: CompressionDraft, _ error: AppError) -> some View {
        VStack(spacing: Spacing.md) {
            failure(error)

            if error.isRetryable {
                Button {
                    Task { await model.startExport(to: draft.defaultDestination) }
                } label: {
                    Text("compression.retry", bundle: .module)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    func inspectionFailed(_ error: AppError) -> some View {
        VStack(spacing: Spacing.md) {
            failure(error)

            chooseButton("compression.choose.another")
        }
    }
}

private extension CompressionView {
    func chooseButton(_ key: LocalizedStringKey) -> some View {
        Button {
            isImporting = true
        } label: {
            Text(key, bundle: .module)
        }
        .buttonStyle(.borderedProminent)
        .padding(.top, Spacing.md)
    }

    func row(_ label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label, bundle: .module)
                .foregroundStyle(AppColor.contentSecondary)

            Spacer(minLength: Spacing.lg)

            Text(verbatim: value)
                .foregroundStyle(AppColor.contentPrimary)
        }
        .font(AppFont.value)
    }

    func failure(_ error: AppError) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(LocalizedStringKey("error." + Self.messageCode(for: error)), bundle: .module)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.contentPrimary)

            if let detail = Self.detail(for: error) {
                Text(verbatim: detail)
                    .font(AppFont.value)
                    .foregroundStyle(AppColor.contentPrimary)
            }

            Text(LocalizedStringKey("recovery." + error.recovery.rawValue), bundle: .module)
                .font(AppFont.body)
                .foregroundStyle(AppColor.contentSecondary)
        }
        .multilineTextAlignment(.center)
    }
}

private extension CompressionView {
    func handleImport(_ result: Result<URL, any Error>) {
        guard case let .success(url) = result else { return }

        // tradeoff: a copy the app owns outright instead of scoped access held accros the whole export, upgrade to security-secoped bookmarks with the FR-8 pickers
        let source = copyIntoTemporary(url) ?? url

        Task { await model.select(source) }
    }

    func copyIntoTemporary(_ url: URL) -> URL? {
        let scoped = url.startAccessingSecurityScopedResource()

        defer {
            if scoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let destination = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension(url.pathExtension)

        do {
            try FileManager.default.copyItem(at: url, to: destination)
        } catch {
            return nil
        }

        return destination
    }
}

extension CompressionView {
    fileprivate static func fraction(of state: ExportJobState) -> Double {
        switch state {
        case let .exporting(progress): progress.fraction
        case .finalizing, .completed: 1
        case .queued, .preparing, .cancelled, .failed: 0
        }
    }

    fileprivate static func bytes(_ count: Int64) -> String {
        count.formatted(.byteCount(style: .file))
    }

    fileprivate static func reduction(_ result: CompressionResult) -> String {
        let percent = result.reductionFraction.formatted(
            .percent.precision(.fractionLength(0))
        )

        return "\(bytes(result.reductionBytes)) (\(percent))"
    }

    fileprivate static func elapsed(_ duration: Duration) -> String {
        duration.formatted(.time(pattern: .minuteSecond))
    }

    fileprivate static func specification(_ configuration: ExportConfiguration) -> String {
        let size = configuration.video.resolution

        return "\(size.width)×\(size.height) · \(configuration.video.codec.rawValue.uppercased())"
            + " · \(configuration.container.rawValue.uppercased())"
    }

    fileprivate static func messageCode(for error: AppError) -> String {
        guard case let .incompatibleConfiguration(reason) = error else { return error.code }

        return reason.code
    }

    static func detail(for error: AppError) -> String? {
        guard case let .incompatibleConfiguration(reason) = error else { return nil }

        switch reason {
        case let .sourceContainerUnreadable(container): return container.identifier
        case let .sourceVideoCodecUnreadable(codec): return codec.identifier
        case let .sourceAudioCodecUnreadable(codec): return codec.identifier
        case let .hdrNotSupportedByOutputCodec(codec): return codec.rawValue.uppercased()
        case let .hardwareEncoderUnavailable(codec): return codec.rawValue.uppercased()
        case let .engineUnavailable(engine): return engine.rawValue
        case .hdrNotSupportedByDevice: return nil
        }
    }
}
