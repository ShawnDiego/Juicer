import Foundation

/// Extracts metadata and information from video data.
public struct VideoExtractor: ContentExtractor {
    public let supportedType: ContentType = .video

    public init() {}

    public func canExtract(from source: ContentSource) -> Bool {
        switch source {
        case .videoData:
            return true
        case .fileURL(let url):
            return Self.videoExtensions.contains(url.pathExtension.lowercased())
        default:
            return false
        }
    }

    public func extract(from source: ContentSource) async throws -> ExtractedContent {
        switch source {
        case .videoData(let data, let filename):
            return extractFromData(data, filename: filename, source: source)
        case .fileURL(let url):
            guard Self.videoExtensions.contains(url.pathExtension.lowercased()) else {
                throw ExtractionError.unsupportedSource
            }
            let data = try Data(contentsOf: url)
            return extractFromData(data, filename: url.lastPathComponent, source: source)
        default:
            throw ExtractionError.unsupportedSource
        }
    }

    // MARK: - Private

    static let videoExtensions: Set<String> = [
        "mp4", "mov", "avi", "mkv", "flv", "wmv", "webm", "m4v", "3gp"
    ]

    func extractFromData(_ data: Data, filename: String?, source: ContentSource) -> ExtractedContent {
        let format = detectVideoFormat(data)

        var metadata: [String: String] = [
            "fileSize": "\(data.count)",
            "fileSizeFormatted": formatFileSize(data.count)
        ]

        if let format = format {
            metadata["videoFormat"] = format
        }

        if let filename = filename {
            metadata["filename"] = filename
        }

        return ExtractedContent(
            contentType: .video,
            source: source,
            title: filename ?? "Video",
            textContent: nil,
            metadata: metadata
        )
    }

    /// Detects the video format from the data's magic bytes.
    func detectVideoFormat(_ data: Data) -> String? {
        guard data.count >= 12 else { return nil }

        let bytes = [UInt8](data.prefix(12))

        // MP4 / MOV (ftyp box)
        if bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            return "MP4"
        }

        // AVI
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46
            && bytes[8] == 0x41 && bytes[9] == 0x56 && bytes[10] == 0x49 {
            return "AVI"
        }

        // FLV
        if bytes[0] == 0x46 && bytes[1] == 0x4C && bytes[2] == 0x56 {
            return "FLV"
        }

        // WebM / MKV (EBML header)
        if bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3 {
            return "WEBM"
        }

        return nil
    }

    func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
