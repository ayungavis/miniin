public struct ExportConfiguration: Sendable, Hashable, Codable {
    public static let currentVersion = 1

    public var container: OutputContainer
    public var video: VideoConfiguration
    public var audio: AudioConfiguration
    public var metadata: MetadataPolicy
    public var hardwareAcceleration: HardwareAccelerationPreference

    public init(
        container: OutputContainer,
        video: VideoConfiguration,
        audio: AudioConfiguration,
        metadata: MetadataPolicy,
        hardwareAcceleration: HardwareAccelerationPreference
    ) {
        self.container = container
        self.video = video
        self.audio = audio
        self.metadata = metadata
        self.hardwareAcceleration = hardwareAcceleration
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case container
        case video
        case audio
        case metadata
        case hardwareAcceleration
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decode(Int.self, forKey: .version)

        guard version == Self.currentVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: values,
                debugDescription: "Unsupported export configuration version \(version)"
            )
        }

        container = try values.decode(OutputContainer.self, forKey: .container)
        video = try values.decode(VideoConfiguration.self, forKey: .video)
        audio = try values.decode(AudioConfiguration.self, forKey: .audio)
        metadata = try values.decode(MetadataPolicy.self, forKey: .metadata)
        hardwareAcceleration = try values.decode(
            HardwareAccelerationPreference.self,
            forKey: .hardwareAcceleration
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(Self.currentVersion, forKey: .version)
        try values.encode(container, forKey: .container)
        try values.encode(video, forKey: .video)
        try values.encode(audio, forKey: .audio)
        try values.encode(metadata, forKey: .metadata)
        try values.encode(hardwareAcceleration, forKey: .hardwareAcceleration)
    }
}

public enum MetadataPolicy: String, Sendable, Codable, CaseIterable {
    case preserve
    case strip
}

public enum HardwareAccelerationPreference: String, Sendable, Codable, CaseIterable {
    case allowSoftwareFallback
    case requireHardware
}
