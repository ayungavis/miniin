import CoreMedia
import Foundation
import VideoToolbox

public enum DeviceCapabilitiesProbe {
    public static func detect() -> DeviceCapabilities {
        let encoders = Set(OutputVideoCodec.allCases.filter { hasHardwareEncoder(for: $0) })

        return DeviceCapabilities(
            hardwareVideoEncoders: encoders,
            // tradeoff: HDR inferred from HEVC, probe Main10 profile support if an 8-bit-only encoder appears
            supportsHDRExport: encoders.contains(.hevc)
        )
    }
}

extension DeviceCapabilitiesProbe {
    fileprivate static func hasHardwareEncoder(for codec: OutputVideoCodec) -> Bool {
        var session: VTCompressionSession?

        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: 1920,
            height: 1080,
            codecType: codecType(for: codec),
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: nil,
            refcon: nil,
            compressionSessionOut: &session
        )

        guard status == noErr, let session else { return false }

        defer { VTCompressionSessionInvalidate(session) }

        return isHardwareAccelerated(session)
    }

    static func codecType(for codec: OutputVideoCodec) -> CMVideoCodecType {
        switch codec {
        case .h264: kCMVideoCodecType_H264
        case .hevc: kCMVideoCodecType_HEVC
        }
    }

    static func isHardwareAccelerated(_ session: VTCompressionSession) -> Bool {
        #if os(macOS)
            var value: CFBoolean?

            let status = VTSessionCopyProperty(
                session,
                key: kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder,
                allocator: kCFAllocatorDefault,
                valueOut: &value
            )

            guard status == noErr, let value else { return false }

            return CFBooleanGetValue(value)
        #else
            // tradeoff: every iOS 18 device has hardware H.264 and HEVC, so a created session is a hardware session
            return true
        #endif
    }
}
