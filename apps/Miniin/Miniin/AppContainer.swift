import MiniinCore
import MiniinEngines
import MiniinFeatures

@MainActor
struct AppContainer {
    let queue: ExportQueueModel
    let compression: CompressionViewModel

    init() {
        let queue = ExportQueueModel(queue: ExportQueue(service: AVFoundationExporter()))

        self.queue = queue
        compression = CompressionViewModel(
            inspection: AVFoundationInspector(),
            files: LocalFileAccess(),
            queue: queue,
            device: DeviceCapabilitiesProbe.detect()
        )

        Log.engineFFmpeg.info("linked libavformat \(FFmpegLink.version, privacy: .public)")
    }
}
