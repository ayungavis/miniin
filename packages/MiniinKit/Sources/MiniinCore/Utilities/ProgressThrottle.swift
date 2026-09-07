public struct ProgressThrottle: Sendable {
    private let minimiumChange: Double
    private let minimumInterval: Duration

    private var lastFraction: Double?
    private var lastInstant: ContinuousClock.Instant?

    public init(minimumChange: Double = 0.005, minimumInterval: Duration = .milliseconds(250)) {
        minimiumChange = minimumChange
        self.minimumInterval = minimumInterval
    }

    public mutating func shouldEmit(_ fraction: Double, at instant: ContinuousClock.Instant) -> Bool {
        guard let lastFraction, let lastInstant else {
            record(fraction, at: instant)
            return true
        }

        guard fraction < 1 else {
            record(fraction, at: instant)
            return true
        }

        guard
            fraction - lastFraction >= minimiumChange
            || instant - lastInstant >= minimumInterval
        else {
            return false
        }

        record(fraction, at: instant)
        return true
    }

    private mutating func record(_ fraction: Double, at instant: ContinuousClock.Instant) {
        lastFraction = fraction
        lastInstant = instant
    }
}
