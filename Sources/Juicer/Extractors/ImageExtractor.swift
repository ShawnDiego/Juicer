import Foundation

/// Extracts metadata and information from image data.
public struct ImageExtractor: ContentExtractor {
    public let supportedType: ContentType = .image

    public init() {}

    public func canExtract(from source: ContentSource) -> Bool {
        switch source {
        case .imageData:
            return true
        case .fileURL(let url):
            return Self.imageExtensions.contains(url.pathExtension.lowercased())
        default:
            return false
        }
    }

    public func extract(from source: ContentSource) async throws -> ExtractedContent {
        switch source {
        case .imageData(let data, let filename):
            return extractFromData(data, filename: filename, source: source)
        case .fileURL(let url):
            guard Self.imageExtensions.contains(url.pathExtension.lowercased()) else {
                throw ExtractionError.unsupportedSource
            }
            let data = try Data(contentsOf: url)
            return extractFromData(data, filename: url.lastPathComponent, source: source)
        default:
            throw ExtractionError.unsupportedSource
        }
    }

    // MARK: - Private

    static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "webp", "heic", "heif"
    ]

    func extractFromData(_ data: Data, filename: String?, source: ContentSource) -> ExtractedContent {
        let format = detectImageFormat(data)

        var metadata: [String: String] = [
            "fileSize": "\(data.count)",
            "fileSizeFormatted": formatFileSize(data.count)
        ]

        if let format = format {
            metadata["imageFormat"] = format
        }

        if let filename = filename {
            metadata["filename"] = filename
        }

        return ExtractedContent(
            contentType: .image,
            source: source,
            title: filename ?? "Image",
            textContent: nil,
            metadata: metadata
        )
    }

    /// Detects the image format from the data's magic bytes.
    func detectImageFormat(_ data: Data) -> String? {
        guard data.count >= 4 else { return nil }

        let bytes = [UInt8](data.prefix(4))

        if bytes[0] == 0xFF && bytes[1] == 0xD8 {
            return "JPEG"
        } else if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return "PNG"
        } else if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 {
            return "GIF"
        } else if bytes[0] == 0x42 && bytes[1] == 0x4D {
            return "BMP"
        } else if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 {
            return "WEBP"
        }

        return nil
    }

    func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
