enum FFmpegLink {
    static var version: String {
        let packed = avformat_version()

        return "\(packed >> 16).\((packed >> 8) & 0xFF).\(packed & 0xFF)"
    }
}
