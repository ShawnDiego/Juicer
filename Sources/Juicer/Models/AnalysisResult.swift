import Foundation

/// Represents the result of analyzing extracted content.
public struct AnalysisResult: Sendable {
    /// The extracted content that was analyzed.
    public let extractedContent: ExtractedContent

    /// A brief summary of the content.
    public let summary: String

    /// Keywords or tags identified in the content.
    public let keywords: [String]

    /// The detected language of the text content.
    public let language: String?

    /// Sentiment or category labels, if applicable.
    public let labels: [String]

    /// Word count of the text content.
    public let wordCount: Int

    /// Whether the content contains media (images or videos).
    public let hasMedia: Bool

    /// Additional analysis metadata.
    public let metadata: [String: String]

    public init(
        extractedContent: ExtractedContent,
        summary: String,
        keywords: [String] = [],
        language: String? = nil,
        labels: [String] = [],
        wordCount: Int = 0,
        hasMedia: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.extractedContent = extractedContent
        self.summary = summary
        self.keywords = keywords
        self.language = language
        self.labels = labels
        self.wordCount = wordCount
        self.hasMedia = hasMedia
        self.metadata = metadata
    }
}
