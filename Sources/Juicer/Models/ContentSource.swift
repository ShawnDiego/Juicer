import Foundation

/// Represents the source input for content extraction.
public enum ContentSource: Sendable, Codable {
    /// A URL string (e.g., a Douyin or Xiaohongshu link).
    case url(String)

    /// Raw text content (e.g., copied text from clipboard).
    case text(String)

    /// Image data with an optional filename.
    case imageData(Data, filename: String?)

    /// Video data with an optional filename.
    case videoData(Data, filename: String?)

    /// A file URL pointing to a local image or video.
    case fileURL(URL)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, stringValue, data, filename, fileURLPath
    }

    private enum SourceType: String, Codable {
        case url, text, imageData, videoData, fileURL
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .url(let value):
            try container.encode(SourceType.url, forKey: .type)
            try container.encode(value, forKey: .stringValue)
        case .text(let value):
            try container.encode(SourceType.text, forKey: .type)
            try container.encode(value, forKey: .stringValue)
        case .imageData(let data, let filename):
            try container.encode(SourceType.imageData, forKey: .type)
            try container.encode(data, forKey: .data)
            try container.encodeIfPresent(filename, forKey: .filename)
        case .videoData(let data, let filename):
            try container.encode(SourceType.videoData, forKey: .type)
            try container.encode(data, forKey: .data)
            try container.encodeIfPresent(filename, forKey: .filename)
        case .fileURL(let url):
            try container.encode(SourceType.fileURL, forKey: .type)
            try container.encode(url.path, forKey: .fileURLPath)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SourceType.self, forKey: .type)
        switch type {
        case .url:
            let value = try container.decode(String.self, forKey: .stringValue)
            self = .url(value)
        case .text:
            let value = try container.decode(String.self, forKey: .stringValue)
            self = .text(value)
        case .imageData:
            let data = try container.decode(Data.self, forKey: .data)
            let filename = try container.decodeIfPresent(String.self, forKey: .filename)
            self = .imageData(data, filename: filename)
        case .videoData:
            let data = try container.decode(Data.self, forKey: .data)
            let filename = try container.decodeIfPresent(String.self, forKey: .filename)
            self = .videoData(data, filename: filename)
        case .fileURL:
            let path = try container.decode(String.self, forKey: .fileURLPath)
            self = .fileURL(URL(fileURLWithPath: path))
        }
    }
}
