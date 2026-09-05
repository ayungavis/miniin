import Foundation

public protocol MediaInspectionService: Sendable {
    func inspect(_ url: URL) async throws(AppError) -> InspectedMedia
}
