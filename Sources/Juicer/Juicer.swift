import Foundation

/// Juicer is the main entry point for content extraction and analysis.
///
/// It accepts various content sources (URLs, text, images, videos) and
/// orchestrates the extraction and analysis pipeline.
///
/// ## Usage
/// ```swift
/// let juicer = Juicer()
///
/// // Process a Douyin link
/// let result = try await juicer.process(input: "https://v.douyin.com/abc123")
///
/// // Process copied text containing a link
/// let result = try await juicer.process(input: "Check this out https://www.xiaohongshu.com/explore/123")
///
/// // Process raw text
/// let result = try await juicer.process(input: "Hello, this is some text to analyze.")
///
/// // Process an image
/// let result = try await juicer.process(source: .imageData(imageData, filename: "photo.jpg"))
///
/// // Process a video
/// let result = try await juicer.process(source: .videoData(videoData, filename: "clip.mp4"))
/// ```
public struct Juicer: Sendable {

    private let linkDetector: LinkDetector
    private let extractors: [ContentExtractor]
    private let analyzer: ContentAnalyzer

    /// Creates a new Juicer instance with default extractors and analyzer.
    public init(
        networkClient: NetworkClient = NetworkClient(),
        analyzer: ContentAnalyzer? = nil
    ) {
        self.linkDetector = LinkDetector()
        self.extractors = [
            DouyinExtractor(networkClient: networkClient),
            XiaohongshuExtractor(networkClient: networkClient),
            TextExtractor(),
            ImageExtractor(),
            VideoExtractor()
        ]
        self.analyzer = analyzer ?? DefaultContentAnalyzer()
    }

    /// Creates a new Juicer instance with custom extractors and analyzer.
    public init(
        extractors: [ContentExtractor],
        analyzer: ContentAnalyzer
    ) {
        self.linkDetector = LinkDetector()
        self.extractors = extractors
        self.analyzer = analyzer
    }

    /// Processes a string input (URL, shared text, or plain text) and returns an analysis result.
    ///
    /// The input is first analyzed to detect any Douyin or Xiaohongshu links.
    /// If a link is found, it is fetched and parsed. Otherwise, the text is analyzed directly.
    ///
    /// - Parameter input: The string to process.
    /// - Returns: An `AnalysisResult` containing the extracted and analyzed content.
    public func process(input: String) async throws -> AnalysisResult {
        let (contentType, cleanedInput) = linkDetector.detect(input)

        let source: ContentSource
        switch contentType {
        case .douyinLink, .xiaohongshuLink:
            source = .url(cleanedInput)
        case .text, .image, .video:
            // LinkDetector.detect() only returns .douyinLink, .xiaohongshuLink, or .text for
            // string input. The .image/.video cases are included for exhaustive switching.
            source = .text(cleanedInput)
        }

        return try await process(source: source)
    }

    /// Processes a content source and returns an analysis result.
    ///
    /// - Parameter source: The `ContentSource` to process.
    /// - Returns: An `AnalysisResult` containing the extracted and analyzed content.
    public func process(source: ContentSource) async throws -> AnalysisResult {
        let extractor = try findExtractor(for: source)
        let content = try await extractor.extract(from: source)
        return try await analyzer.analyze(content)
    }

    /// Extracts content without performing analysis.
    ///
    /// - Parameter source: The `ContentSource` to extract from.
    /// - Returns: The `ExtractedContent`.
    public func extract(source: ContentSource) async throws -> ExtractedContent {
        let extractor = try findExtractor(for: source)
        return try await extractor.extract(from: source)
    }

    /// Extracts content from a string input without performing analysis.
    ///
    /// - Parameter input: The string to extract from.
    /// - Returns: The `ExtractedContent`.
    public func extract(input: String) async throws -> ExtractedContent {
        let (contentType, cleanedInput) = linkDetector.detect(input)

        let source: ContentSource
        switch contentType {
        case .douyinLink, .xiaohongshuLink:
            source = .url(cleanedInput)
        case .text, .image, .video:
            // LinkDetector.detect() only returns .douyinLink, .xiaohongshuLink, or .text for
            // string input. The .image/.video cases are included for exhaustive switching.
            source = .text(cleanedInput)
        }

        let extractor = try findExtractor(for: source)
        return try await extractor.extract(from: source)
    }

    // MARK: - Private

    private func findExtractor(for source: ContentSource) throws -> ContentExtractor {
        guard let extractor = extractors.first(where: { $0.canExtract(from: source) }) else {
            throw ExtractionError.unsupportedSource
        }
        return extractor
    }
}
