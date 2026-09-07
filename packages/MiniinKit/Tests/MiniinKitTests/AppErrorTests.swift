import MiniinCore
import Testing

@Suite("App error")
struct AppErrorTests {
    @Test("Error codes are pinned")
    func codesArePinned() {
        let storage = AppError.insufficientStorage(requiredBytes: 1, availableBytes: 0)
        let incompatible = AppError.incompatibleConfiguration(.hdrNotSupportedByDevice)

        #expect(incompatible.code == "configuration.incompatible")
        #expect(AppError.corruptedMedia.code == "media.corrupted")
        #expect(storage.code == "storage.insufficient")
        #expect(AppError.permissionExpired.code == "permission.expired")
        #expect(AppError.outputExists.code == "output.exists")
        #expect(AppError.exportInterrupted.code == "export.interrupted")
    }

    @Test("Only an interrupted export is retryable")
    func onlyInterruptedExportIsRetryable() {
        let storage = AppError.insufficientStorage(requiredBytes: 1, availableBytes: 0)
        let incompatible = AppError.incompatibleConfiguration(.hdrNotSupportedByDevice)

        #expect(AppError.exportInterrupted.isRetryable)

        #expect(!incompatible.isRetryable)
        #expect(!AppError.corruptedMedia.isRetryable)
        #expect(!storage.isRetryable)
        #expect(!AppError.permissionExpired.isRetryable)
        #expect(!AppError.outputExists.isRetryable)
    }

    @Test("Each failure offers a specific recovery")
    func recoveriesAreSpecific() {
        let storage = AppError.insufficientStorage(requiredBytes: 1, availableBytes: 0)

        #expect(AppError.corruptedMedia.recovery == .chooseAnotherVideo)
        #expect(storage.recovery == .freeUpStorage)
        #expect(AppError.permissionExpired.recovery == .reauthorizeDestination)
        #expect(AppError.outputExists.recovery == .resolveNameConflict)
        #expect(AppError.exportInterrupted.recovery == .retryExport)
    }

    @Test("One incompatibility case offers three different recoveries")
    func incompatibilityRecoveriesDiffer() {
        let unreadable = AppError.incompatibleConfiguration(.sourceVideoCodecUnreadable(.vp9))
        let hdr = AppError.incompatibleConfiguration(.hdrNotSupportedByDevice)
        let hardware = AppError.incompatibleConfiguration(.hardwareEncoderUnavailable(.hevc))

        #expect(unreadable.recovery == .chooseAnotherVideo)
        #expect(hdr.recovery == .convertToSDR)
        #expect(hardware.recovery == .allowSoftwareEncoding)
    }
}
