import Foundation
import Testing
@testable import MiniinKit

@Suite("Local file access")
struct LocalFileAccessTests {
    private let access = LocalFileAccess()

    @Test("A free name is returned unchanged")
    func freeNameIsReturnedUnchanged() {
        let url = URL(filePath: "/tmp/clip.mp4")

        #expect(LocalFileAccess.uniqueURL(for: url) { _ in false } == url)
    }

    @Test("Conflicting names are numbered from two")
    func conflictingNamesAreNumberedFromTwo() {
        let url = URL(filePath: "/tmp/clip.mp4")
        let taken: Set<URL> = [url, URL(filePath: "/tmp/clip 2.mp4")]
        let result = LocalFileAccess.uniqueURL(for: url) { taken.contains($0) }

        #expect(result == URL(filePath: "/tmp/clip 3.mp4"))
    }

    @Test("An exhausted range falls back to a non-colliding suffix")
    func exhaustedRangeFallsBackToAUniqueSuffix() {
        let url = URL(filePath: "/tmp/clip.mp4")
        var taken: Set<URL> = [url]

        for index in 2 ... 99 {
            taken.insert(URL(filePath: "/tmp/clip \(index).mp4"))
        }

        let result = LocalFileAccess.uniqueURL(for: url) { taken.contains($0) }

        #expect(!taken.contains(result))
        #expect(result.pathExtension == "mp4")
    }

    @Test("Temporary URLs carry the container extension and differ between calls")
    func temporaryURLsCarryTheExtensionAndDiffer() throws {
        let configuration = try Self.configuration()
        let first = access.temporaryOutputURL(for: configuration)
        let second = access.temporaryOutputURL(for: configuration)

        #expect(first.pathExtension == "mp4")
        #expect(first != second)
    }

    @Test("An impossible requirement reports insufficient storage")
    func impossibleRequirementReportsInsufficientStorage() {
        do {
            try access.ensureSpace(
                forEstimatedBytes: .max,
                at: FileManager.default.temporaryDirectory
            )

            Issue.record("expected insufficientStorage")
        } catch {
            guard case let .insufficientStorage(required, available) = error else {
                Issue.record("expected insufficientStorage, got \(error)")
                return
            }

            #expect(required == .max)
            #expect(available < .max)
        }
    }

    @Test("Keeping both writes beside the existing file")
    func keepingBothWritesBesideTheExistingFile() throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = try Self.file(in: directory, named: "clip.mp4", contents: "existing")
        let temporary = try Self.file(in: directory, named: "staged.tmp", contents: "new")
        let result = try access.promote(temporary, to: destination, conflict: .keepBoth)

        #expect(result.lastPathComponent == "clip 2.mp4")
        #expect(FileManager.default.fileExists(atPath: destination.path()))
    }

    @Test("Failing on a conflict reports that the output exists")
    func failingOnAConflictReportsOutputExists() throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = try Self.file(in: directory, named: "clip.mp4", contents: "existing")
        let temporary = try Self.file(in: directory, named: "staged.tmp", contents: "new")

        #expect(throws: AppError.outputExists) {
            try access.promote(temporary, to: destination, conflict: .fail)
        }
    }

    @Test("Replacing overwrites the existing file")
    func replacingOverwritesTheExistingFile() throws {
        let directory = try Self.directory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = try Self.file(in: directory, named: "clip.mp4", contents: "existing")
        let temporary = try Self.file(in: directory, named: "staged.tmp", contents: "new")
        let result = try access.promote(temporary, to: destination, conflict: .replace)

        #expect(result == destination)
        #expect(try String(contentsOf: result, encoding: .utf8) == "new")
    }
}

extension LocalFileAccessTests {
    static func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

    static func file(in directory: URL, named name: String, contents: String) throws -> URL {
        let url = directory.appending(path: name)
        try Data(contents.utf8).write(to: url)

        return url
    }

    static func configuration() throws -> ExportConfiguration {
        let resolution = try #require(PixelDimensions(width: 1920, height: 1080))
        let bitrate = try #require(Bitrate(bitsPerSecond: 4_000_000))

        return ExportConfiguration(
            container: .mp4,
            video: VideoConfiguration(
                codec: .h264,
                resolution: resolution,
                frameRate: .fps30,
                rateControl: .averageBitrate(target: bitrate),
                dynamicRange: .convertToSDR
            ),
            audio: .removed,
            metadata: .strip,
            hardwareAcceleration: .allowSoftwareFallback
        )
    }
}
