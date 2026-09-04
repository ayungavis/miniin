public struct SourceContainer: MediaIdentifier, Hashable {
    public let identifier: String

    public init(_ identifier: String) {
        self.identifier = identifier
    }
}

public extension SourceContainer {
    static let mp4 = SourceContainer("mp4")
    static let mov = SourceContainer("mov")
    static let m4v = SourceContainer("m4v")
    static let mkv = SourceContainer("mkv")
    static let webm = SourceContainer("webm")
    static let avi = SourceContainer("avi")
}
