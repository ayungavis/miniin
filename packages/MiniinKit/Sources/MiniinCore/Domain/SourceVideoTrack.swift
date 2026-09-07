public struct SourceVideoTrack: Sendable, Hashable, Codable {
    public let codec: SourceVideoCodec
    public let dimensions: PixelDimensions
    public let frameRate: FrameRate
    public let dynamicRange: SourceDynamicRange
    public let rotation: Rotation

    public var displayDimensions: PixelDimensions {
        switch rotation {
        case .upright, .halfTurn:
            dimensions
        case .quarterTurn, .threeQuarterTurn:
            PixelDimensions(width: dimensions.height, height: dimensions.width) ?? dimensions
        }
    }

    public init(
        codec: SourceVideoCodec,
        dimensions: PixelDimensions,
        frameRate: FrameRate,
        dynamicRange: SourceDynamicRange,
        rotation: Rotation
    ) {
        self.codec = codec
        self.dimensions = dimensions
        self.frameRate = frameRate
        self.dynamicRange = dynamicRange
        self.rotation = rotation
    }
}

public enum SourceDynamicRange: String, Sendable, Codable, CaseIterable {
    case sdr
    case hdr
    case unknown
}

public enum Rotation: Int, Sendable, Codable, CaseIterable {
    case upright = 0
    case quarterTurn = 90
    case halfTurn = 180
    case threeQuarterTurn = 270
}
