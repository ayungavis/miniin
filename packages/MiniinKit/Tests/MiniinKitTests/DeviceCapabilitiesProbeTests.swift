import MiniinCore
import Testing
@testable import MiniinEngines

@Suite("Device capabilities probe")
struct DeviceCapabilitiesProbeTests {
    @Test("Detection is deterministic")
    func detectionIsDeterministic() {
        #expect(DeviceCapabilitiesProbe.detect() == DeviceCapabilitiesProbe.detect())
    }

    @Test("Hardware H.264 encoding is available")
    func h264EncodingIsAvailable() {
        #expect(DeviceCapabilitiesProbe.detect().hardwareVideoEncoders.contains(.h264))
    }

    @Test("HDR export implies an HEVC encoder")
    func hdrExportImpliesHEVC() {
        let capabilities = DeviceCapabilitiesProbe.detect()

        #expect(
            !capabilities.supportsHDRExport || capabilities.hardwareVideoEncoders.contains(.hevc)
        )
    }
}
