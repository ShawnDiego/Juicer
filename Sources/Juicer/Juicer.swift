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
///
/// // Batch process multiple inputs
/// let results = try await juicer.processAll(inputs: ["text1", "https://v.douyin.com/abc"])
///
/// // Read from clipboard (iOS/macOS)
/// if let source = juicer.readClipboard() {
///     let result = try await juicer.process(source: source)
/// }
/// ```
public struct Juicer: Sendable {

    private let linkDetector: LinkDetector
    private let extractors: [ContentExtractor]
    private let analyzer: ContentAnalyzer
    private let cache: ContentCache?

    /// The configuration used by this Juicer instance.
    public let configuration: JuicerConfiguration

    /// The clipboard reader for accessing system clipboard content.
    public let clipboardReader: ClipboardReader

    /// Creates a new Juicer instance with default extractors and analyzer.
    public init(
        configuration: JuicerConfiguration = .default,
        analyzer: ContentAnalyzer? = nil
    ) {
        let networkClient = NetworkClient(
            userAgent: configuration.userAgent,
            timeout: configuration.networkTimeout
        )
        self.configuration = configuration
        self.linkDetector = LinkDetector()
        self.extractors = [
            DouyinExtractor(networkClient: networkClient),
            XiaohongshuExtractor(networkClient: networkClient),
            GenericURLExtractor(networkClient: networkClient),
            TextExtractor(),
            ImageExtractor(),
            VideoExtractor()
        ]
        self.analyzer = analyzer ?? DefaultContentAnalyzer()
        self.cache = configuration.cachingEnabled ? ContentCache(maxSize: configuration.maxCacheSize) : nil
        self.clipboardReader = ClipboardReader()
    }

    /// Creates a new Juicer instance with custom extractors and analyzer.
    public init(
        extractors: [ContentExtractor],
        analyzer: ContentAnalyzer,
        configuration: JuicerConfiguration = .default
    ) {
        self.configuration = configuration
        self.linkDetector = LinkDetector()
        self.extractors = extractors
        self.analyzer = analyzer
        self.cache = configuration.cachingEnabled ? ContentCache(maxSize: configuration.maxCacheSize) : nil
        self.clipboardReader = ClipboardReader()
    }

    // MARK: - Single Processing

    /// Processes a string input (URL, shared text, or plain text) and returns an analysis result.
    ///
    /// The input is first analyzed to detect any Douyin or Xiaohongshu links.
    /// If a link is found, it is fetched and parsed. Otherwise, the text is analyzed directly.
    ///
    /// - Parameter input: The string to process.
    /// - Returns: An `AnalysisResult` containing the extracted and analyzed content.
    public func process(input: String) async throws -> AnalysisResult {
        let source = resolveSource(from: input)
        return try await process(source: source)
    }

    /// Processes a content source and returns an analysis result.
    ///
    /// - Parameter source: The `ContentSource` to process.
    /// - Returns: An `AnalysisResult` containing the extracted and analyzed content.
    public func process(source: ContentSource) async throws -> AnalysisResult {
        let cacheKey = ContentCache.cacheKey(for: source)

        // Check analysis cache
        if let cached = cache?.getAnalysis(for: cacheKey) {
            return cached
        }

        let content = try await extractWithCache(source: source, cacheKey: cacheKey)
        let result = try await analyzer.analyze(content)

        cache?.setAnalysis(result, for: cacheKey)
        return result
    }

    // MARK: - Extraction Only

    /// Extracts content without performing analysis.
    ///
    /// - Parameter source: The `ContentSource` to extract from.
    /// - Returns: The `ExtractedContent`.
    public func extract(source: ContentSource) async throws -> ExtractedContent {
        let cacheKey = ContentCache.cacheKey(for: source)
        return try await extractWithCache(source: source, cacheKey: cacheKey)
    }

    /// Extracts content from a string input without performing analysis.
    ///
    /// - Parameter input: The string to extract from.
    /// - Returns: The `ExtractedContent`.
    public func extract(input: String) async throws -> ExtractedContent {
        let source = resolveSource(from: input)
        return try await extract(source: source)
    }

    // MARK: - Batch Processing

    /// Processes multiple string inputs concurrently and returns results for each.
    ///
    /// Failed inputs are represented as `nil` in the returned array.
    /// The `maxConcurrency` from the configuration controls parallelism.
    ///
    /// - Parameter inputs: The array of string inputs to process.
    /// - Returns: An array of optional `AnalysisResult`, one per input.
    public func processAll(inputs: [String]) async -> [AnalysisResult?] {
        return await withTaskGroup(of: (Int, AnalysisResult?).self) { group in
            for (index, input) in inputs.enumerated() {
                group.addTask {
                    let result = try? await self.process(input: input)
                    return (index, result)
                }
            }

            var results = [AnalysisResult?](repeating: nil, count: inputs.count)
            for await (index, result) in group {
                results[index] = result
            }
            return results
        }
    }

    /// Processes multiple content sources concurrently and returns results for each.
    ///
    /// Failed sources are represented as `nil` in the returned array.
    ///
    /// - Parameter sources: The array of `ContentSource` to process.
    /// - Returns: An array of optional `AnalysisResult`, one per source.
    public func processAll(sources: [ContentSource]) async -> [AnalysisResult?] {
        return await withTaskGroup(of: (Int, AnalysisResult?).self) { group in
            for (index, source) in sources.enumerated() {
                group.addTask {
                    let result = try? await self.process(source: source)
                    return (index, result)
                }
            }

            var results = [AnalysisResult?](repeating: nil, count: sources.count)
            for await (index, result) in group {
                results[index] = result
            }
            return results
        }
    }

    // MARK: - Clipboard

    /// Reads the current system clipboard and returns a `ContentSource`, or `nil` if empty.
    public func readClipboard() -> ContentSource? {
        return clipboardReader.read()
    }

    /// Reads from clipboard and processes the content directly.
    ///
    /// - Throws: `ExtractionError.noContentFound` if clipboard is empty.
    /// - Returns: An `AnalysisResult` from the clipboard content.
    public func processClipboard() async throws -> AnalysisResult {
        guard let source = clipboardReader.read() else {
            throw ExtractionError.noContentFound
        }
        return try await process(source: source)
    }

    // MARK: - Cache Management

    /// Clears the in-memory cache.
    public func clearCache() {
        cache?.clear()
    }

    // MARK: - Private

    private func resolveSource(from input: String) -> ContentSource {
        let (contentType, cleanedInput) = linkDetector.detect(input)
        switch contentType {
        case .douyinLink, .xiaohongshuLink:
            return .url(cleanedInput)
        case .text, .image, .video:
            // LinkDetector.detect() only returns .douyinLink, .xiaohongshuLink, or .text for
            // string input. The .image/.video cases are included for exhaustive switching.
            return .text(cleanedInput)
        }
    }

    private func extractWithCache(source: ContentSource, cacheKey: String) async throws -> ExtractedContent {
        if let cached = cache?.getExtraction(for: cacheKey) {
            return cached
        }

        let extractor = try findExtractor(for: source)
        let content = try await extractor.extract(from: source)

        cache?.setExtraction(content, for: cacheKey)
        return content
    }

    private func findExtractor(for source: ContentSource) throws -> ContentExtractor {
        guard let extractor = extractors.first(where: { $0.canExtract(from: source) }) else {
            throw ExtractionError.unsupportedSource
        }
        return extractor
    }
}
