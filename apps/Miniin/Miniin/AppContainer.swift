import MiniinKit

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
    }
}
