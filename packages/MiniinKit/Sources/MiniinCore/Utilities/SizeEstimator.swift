public enum SizeEstimator {
    public static func estimate(
        duration: Duration,
        configuration: ExportConfiguration
    ) -> SizeEstimate? {
        guard case let .averageBitrate(target) = configuration.video.rateControl else {
            return nil
        }

        let bitsPerSecond = target.bitsPerSecond + audioBitsPerSecond(configuration.audio)
        let bytes = seconds(of: duration) * Double(bitsPerSecond) / 8 * containerOverhead

        return SizeEstimate(
            lowerBytes: Int64(bytes * (1 - tolerance)),
            upperBytes: Int64(bytes * (1 + tolerance))
        )
    }
}

private extension SizeEstimator {
    // tradeoff: overhead and tolerance are guesses until the Phase 0 estimation prototype measures them
    static let containerOverhead = 1.02
    static let tolerance = 0.1

    static func audioBitsPerSecond(_ audio: AudioConfiguration) -> Int {
        switch audio {
        case .removed: 0
        case let .encoded(settings): settings.bitrate.bitsPerSecond
        }
    }

    static func seconds(of duration: Duration) -> Double {
        let components = duration.components

        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}
