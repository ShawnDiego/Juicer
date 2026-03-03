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
/// // Process a Weibo link
/// let result = try await juicer.process(input: "https://weibo.com/1234567890/abcdef")
///
/// // Process a generic URL (any HTTP/HTTPS link embedded in text)
/// let result = try await juicer.process(input: "Look at this https://example.com/article")
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
            WeiboExtractor(networkClient: networkClient),
            GenericURLExtractor(networkClient: networkClient),
            TextExtractor(),
            ImageExtractor(),
            VideoExtractor()
        ]
        self.analyzer = analyzer ?? DefaultContentAnalyzer(maxKeywords: configuration.maxKeywords)
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
    /// The input is first analyzed to detect any Douyin, Xiaohongshu, or Weibo links.
    /// If a platform link is found, it is fetched and parsed. If a generic URL is found,
    /// it is fetched for Open Graph metadata. Otherwise, the text is analyzed directly.
    ///
    /// - Parameter input: The string to process.
    /// - Returns: An `AnalysisResult` containing the extracted and analyzed content.
    /// - Throws: `ExtractionError.textTooLong` if input exceeds `maxTextLength` (when configured).
    public func process(input: String) async throws -> AnalysisResult {
        try validateTextLength(input)
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
    /// - Throws: `ExtractionError.textTooLong` if input exceeds `maxTextLength` (when configured).
    public func extract(input: String) async throws -> ExtractedContent {
        try validateTextLength(input)
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
        let maxConcurrency = configuration.maxConcurrency

        return await withTaskGroup(of: (Int, AnalysisResult?).self) { group in
            var nextIndex = 0
            var results = [AnalysisResult?](repeating: nil, count: inputs.count)

            // Seed the group with initial tasks up to maxConcurrency
            while nextIndex < min(maxConcurrency, inputs.count) {
                let index = nextIndex
                group.addTask {
                    let result = try? await self.process(input: inputs[index])
                    return (index, result)
                }
                nextIndex += 1
            }

            // As each task completes, add the next one
            for await (completedIndex, result) in group {
                results[completedIndex] = result

                if nextIndex < inputs.count {
                    let currentIndex = nextIndex
                    group.addTask {
                        let result = try? await self.process(input: inputs[currentIndex])
                        return (currentIndex, result)
                    }
                    nextIndex += 1
                }
            }

            return results
        }
    }

    /// Processes multiple content sources concurrently and returns results for each.
    ///
    /// Failed sources are represented as `nil` in the returned array.
    /// The `maxConcurrency` from the configuration controls parallelism.
    ///
    /// - Parameter sources: The array of `ContentSource` to process.
    /// - Returns: An array of optional `AnalysisResult`, one per source.
    public func processAll(sources: [ContentSource]) async -> [AnalysisResult?] {
        let maxConcurrency = configuration.maxConcurrency

        return await withTaskGroup(of: (Int, AnalysisResult?).self) { group in
            var nextIndex = 0
            var results = [AnalysisResult?](repeating: nil, count: sources.count)

            // Seed the group with initial tasks up to maxConcurrency
            while nextIndex < min(maxConcurrency, sources.count) {
                let index = nextIndex
                group.addTask {
                    let result = try? await self.process(source: sources[index])
                    return (index, result)
                }
                nextIndex += 1
            }

            // As each task completes, add the next one
            for await (completedIndex, result) in group {
                results[completedIndex] = result

                if nextIndex < sources.count {
                    let currentIndex = nextIndex
                    group.addTask {
                        let result = try? await self.process(source: sources[currentIndex])
                        return (currentIndex, result)
                    }
                    nextIndex += 1
                }
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
        case .douyinLink, .xiaohongshuLink, .weiboLink:
            return .url(cleanedInput)
        case .text, .image, .video:
            // If no platform link was detected, check for generic URLs
            let urls = linkDetector.extractURLs(from: input)
            if let firstURL = urls.first, linkDetector.isGenericURL(firstURL) {
                return .url(firstURL)
            }
            return .text(cleanedInput)
        }
    }

    private func validateTextLength(_ input: String) throws {
        let maxLength = configuration.maxTextLength
        guard maxLength == 0 || input.count <= maxLength else {
            throw ExtractionError.textTooLong(maxLength)
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
