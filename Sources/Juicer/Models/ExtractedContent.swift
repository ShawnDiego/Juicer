import Foundation

/// Represents content extracted from a source.
public struct ExtractedContent: Sendable {
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
}
