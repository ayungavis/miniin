import MiniinKit
import Testing

@Suite("Engine support")
struct EngineSupportTests {
    @Test("FFmpeg reads everything AVFoundation reads")
    func ffmpegIsAReadSupersetOfAVFoundation() {
        #expect(
            AVFoundationSupport.readableContainers.isSubset(of: FFmpegSupport.readableContainers)
        )
        #expect(
            AVFoundationSupport.readableVideoCodecs.isSubset(of: FFmpegSupport.readableVideoCodecs)
        )
        #expect(
            AVFoundationSupport.readableAudioCodecs.isSubset(of: FFmpegSupport.readableAudioCodecs)
        )
    }

    @Test("Every output format is writable by at least one engine")
    func everyOutputFormatIsWritable() {
        let writable = AVFoundationSupport.writableFormats.union(FFmpegSupport.writableFormats)

        for container in OutputContainer.allCases {
            for codec in OutputVideoCodec.allCases {
                #expect(writable.contains(OutputFormat(container: container, codec: codec)))
            }
        }
    }
}
