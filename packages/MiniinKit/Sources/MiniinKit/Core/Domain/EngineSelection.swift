public enum EngineSelection: Sendable, Hashable {
    case avFoundation(plan: ExportPlan)
    case ffmpeg(plan: ExportPlan)
    case unsupported(reason: IncompatibilityReason)
}
