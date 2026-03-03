import Foundation

/// Represents the source input for content extraction.
public enum ContentSource: Sendable {
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
}
