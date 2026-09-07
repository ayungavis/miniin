import Foundation
import os

public enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.miniin.app"

    public static let app = Logger(subsystem: subsystem, category: "app")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
    public static let inspection = Logger(subsystem: subsystem, category: "inspection")
    public static let estimation = Logger(subsystem: subsystem, category: "estimation")
    public static let queue = Logger(subsystem: subsystem, category: "queue")
    public static let engineAVFoundation = Logger(
        subsystem: subsystem, category: "engine.avfoundation"
    )
    public static let engineFFmpeg = Logger(subsystem: subsystem, category: "engine.ffmpeg")
    public static let fileAccess = Logger(subsystem: subsystem, category: "file")
    public static let persistence = Logger(subsystem: subsystem, category: "persistence")
    public static let purchases = Logger(subsystem: subsystem, category: "purchases")
    public static let remote = Logger(subsystem: subsystem, category: "remote")

    public static func report(
        _ error: some Error,
        in logger: Logger = Log.app,
        operation: StaticString = #function
    ) {
        logger.error(
            "\(operation, privacy: .public) failed: \(signature(of: error), privacy: .public)"
        )
    }

    private static func signature(of error: some Error) -> String {
        if let appError = error as? AppError {
            return appError.code
        }
        let nsError = error as NSError
        return "\(nsError.domain)#\(nsError.code)"
    }
}
