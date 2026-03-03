import Foundation

/// Represents content extracted from a source.
public struct ExtractedContent: Sendable, Codable {
    /// The type of content that was extracted.
    public let contentType: ContentType

    /// The original source of the content.
    public let source: ContentSource

    /// The title extracted from the content, if available.
    public let title: String?

    /// The main text or description extracted.
    public let textContent: String?

    /// URLs of images found in the content.
    public let imageURLs: [String]

    /// URLs of videos found in the content.
    public let videoURLs: [String]

    /// The author or creator name, if available.
    public let author: String?

    /// Additional metadata as key-value pairs.
    public let metadata: [String: String]

    /// The date the content was originally created, if available.
    public let createdAt: Date?

    /// The date this extraction was performed.
    public let extractedAt: Date

    public init(
        contentType: ContentType,
        source: ContentSource,
        title: String? = nil,
        textContent: String? = nil,
        imageURLs: [String] = [],
        videoURLs: [String] = [],
        author: String? = nil,
        metadata: [String: String] = [:],
        createdAt: Date? = nil,
        extractedAt: Date = Date()
    ) {
        self.contentType = contentType
        self.source = source
        self.title = title
        self.textContent = textContent
        self.imageURLs = imageURLs
        self.videoURLs = videoURLs
        self.author = author
        self.metadata = metadata
        self.createdAt = createdAt
        self.extractedAt = extractedAt
    }

    // MARK: - Convenience

    /// The primary download URL for the content.
    ///
    /// For video content, this returns the first video URL.
    /// For image content, this returns the first image URL.
    /// For link content with videos, the video URL takes precedence.
    /// Returns `nil` if no media URLs are available.
    public var downloadURL: String? {
        if !videoURLs.isEmpty {
            return videoURLs.first
        }
        if !imageURLs.isEmpty {
            return imageURLs.first
        }
        return nil
    }

    /// The resolved URL after following redirects, if available.
    ///
    /// This is particularly useful for short URLs (e.g., Douyin's `v.douyin.com/xxx`)
    /// that redirect to the actual content page. Stored in `metadata["resolvedURL"]`.
    public var resolvedURL: String? {
        return metadata["resolvedURL"]
    }

    /// The platform-specific content ID, if available.
    ///
    /// For example, Douyin video IDs are stored in `metadata["videoId"]`.
    public var contentId: String? {
        return metadata["videoId"] ?? metadata["noteId"] ?? metadata["contentId"]
    }
}
