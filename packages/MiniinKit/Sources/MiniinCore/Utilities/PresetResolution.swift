public enum PresetResolution {
    public static func dimensions(
        for rule: ResolutionRule,
        source: PixelDimensions,
        allowUpscaling: Bool
    ) -> PixelDimensions {
        switch rule {
        case .matchSource:
            return source
        case let .longestSideAtMost(cap):
            let longest = max(source.width, source.height)

            guard longest > cap || allowUpscaling else { return source }

            let scale = Double(cap) / Double(longest)

            return PixelDimensions(
                width: even(Double(source.width) * scale),
                height: even(Double(source.height) * scale)
            ) ?? source
        }
    }

    public static func frameRate(for rule: FrameRateRule, source: FrameRate) -> FrameRate {
        switch rule {
        case .matchSource:
            source
        case let .atMost(cap):
            source.value <= cap.value ? source : cap
        }
    }

    public static func rateControl(
        for rule: RateControlRule,
        dimensions: PixelDimensions,
        frameRate: FrameRate
    ) -> RateControl? {
        switch rule {
        case let .bitsPerPixel(density):
            let pixels = Double(dimensions.width * dimensions.height)

            guard let bitrate = Bitrate(bitsPerSecond: Int(density * pixels * frameRate.value))
            else {
                return nil
            }

            return .averageBitrate(target: bitrate)
        case let .constantQuality(percent):
            guard let level = QualityLevel(percent: percent) else { return nil }

            return .constantQuality(level: level)
        }
    }

    public static func audio(for rule: AudioRule) -> AudioConfiguration? {
        switch rule {
        case .removed:
            return .removed

        case let .encoded(codec, bitsPersecond, channels):
            guard let bitrate = Bitrate(bitsPerSecond: bitsPersecond) else {
                return nil
            }

            return .encoded(
                settings: AudioSettings(codec: codec, bitrate: bitrate, channels: channels)
            )
        }
    }

    static func even(_ value: Double) -> Int {
        max(2, Int(value.rounded()) / 2 * 2)
    }
}
