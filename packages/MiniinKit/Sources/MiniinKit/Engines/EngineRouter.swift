public struct EngineRouter: Sendable {
    public init() {}

    public func route(
        source: SourceCapabilities,
        device: DeviceCapabilities,
        configuration: ExportConfiguration
    ) -> EngineSelection {
        let wantsAudio = configuration.audio != .removed

        if let reason = Self.sourceFailure(source, wantsAudio: wantsAudio) {
            return .unsupported(reason: reason)
        }

        if let reason = Self.dynamicRangeFailure(
            source, device: device, configuration: configuration
        ) {
            return .unsupported(reason: reason)
        }

        if let reason = Self.hardwareFailure(device: device, configuration: configuration) {
            return .unsupported(reason: reason)
        }

        let plan = Self.plan(source, device: device, configuration: configuration)

        return Self.avFoundationCanHandle(
            source, configuration: configuration, wantsAudio: wantsAudio
        )
            ? .avFoundation(plan: plan) : .ffmpeg(plan: plan)
    }
}

extension EngineRouter {
    static func sourceFailure(
        _ source: SourceCapabilities,
        wantsAudio: Bool
    ) -> IncompatibilityReason? {
        guard FFmpegSupport.readableContainers.contains(source.container) else {
            return .sourceContainerUnreadable(source.container)
        }

        guard FFmpegSupport.readableVideoCodecs.contains(source.video.codec) else {
            return .sourceVideoCodecUnreadable(source.video.codec)
        }

        guard wantsAudio, let audio = source.audio else { return nil }

        guard FFmpegSupport.readableAudioCodecs.contains(audio.codec) else {
            return .sourceAudioCodecUnreadable(audio.codec)
        }

        return nil
    }

    static func dynamicRangeFailure(
        _ source: SourceCapabilities,
        device: DeviceCapabilities,
        configuration: ExportConfiguration
    ) -> IncompatibilityReason? {
        guard source.video.dynamicRange == .hdr, configuration.video.dynamicRange == .preserve
        else {
            return nil
        }

        guard configuration.video.codec == .hevc else {
            return .hdrNotSupportedByOutputCodec(configuration.video.codec)
        }

        guard device.supportsHDRExport else {
            return .hdrNotSupportedByDevice
        }

        return nil
    }

    static func hardwareFailure(
        device: DeviceCapabilities,
        configuration: ExportConfiguration
    ) -> IncompatibilityReason? {
        guard configuration.hardwareAcceleration == .requireHardware,
              !device.hardwareVideoEncoders.contains(configuration.video.codec)
        else {
            return nil
        }

        return .hardwareEncoderUnavailable(configuration.video.codec)
    }

    static func plan(
        _ source: SourceCapabilities,
        device: DeviceCapabilities,
        configuration: ExportConfiguration
    ) -> ExportPlan {
        let hasHardwareEncoder = device.hardwareVideoEncoders.contains(configuration.video.codec)
        let toneMaps =
            source.video.dynamicRange == .hdr && configuration.video.dynamicRange == .convertToSDR

        return ExportPlan(
            videoEncoder: hasHardwareEncoder ? .hardware : .software, requiresToneMapping: toneMaps
        )
    }

    static func avFoundationCanHandle(
        _ source: SourceCapabilities,
        configuration: ExportConfiguration,
        wantsAudio: Bool
    ) -> Bool {
        let format = OutputFormat(
            container: configuration.container, codec: configuration.video.codec
        )

        guard AVFoundationSupport.writableFormats.contains(format),
              AVFoundationSupport.readableContainers.contains(source.container),
              AVFoundationSupport.readableVideoCodecs.contains(source.video.codec)
        else {
            return false
        }

        guard wantsAudio, let audio = source.audio else { return true }

        return AVFoundationSupport.readableAudioCodecs.contains(audio.codec)
    }
}
