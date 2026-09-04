public struct VideoConfiguration: Sendable, Hashable, Codable {
    public var codec: OutputVideoCodec
    public var resolution: PixelDimensions
    public var frameRate: FrameRate
    public var rateControl: RateControl
    public var dynamicRange: DynamicRangePolicy

    public init(
        codec: OutputVideoCodec,
        resolution: PixelDimensions,
        frameRate: FrameRate,
        rateControl: RateControl,
        dynamicRange: DynamicRangePolicy
    ) {
        self.codec = codec
        self.resolution = resolution
        self.frameRate = frameRate
        self.rateControl = rateControl
        self.dynamicRange = dynamicRange
    }
}

public enum DynamicRangePolicy: String, Sendable, Codable, CaseIterable {
    case preserve
    case convertToSDR
}
