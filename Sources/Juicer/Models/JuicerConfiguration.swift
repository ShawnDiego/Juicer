import Foundation

/// Configuration options for the Juicer processing pipeline.
public struct JuicerConfiguration: Sendable {
    /// The maximum number of concurrent operations for batch processing.
    public let maxConcurrency: Int

    /// The network request timeout interval in seconds.
    public let networkTimeout: TimeInterval

    /// Whether to enable in-memory caching of extracted content.
    public let cachingEnabled: Bool

    /// The maximum number of items to keep in the cache.
    public let maxCacheSize: Int

    /// The maximum text length to process (0 = unlimited).
    public let maxTextLength: Int

    /// The maximum number of keywords to extract during analysis.
    public let maxKeywords: Int

    /// The User-Agent string for network requests.
    public let userAgent: String

    /// The default configuration.
    public static let `default` = JuicerConfiguration()

    public init(
        maxConcurrency: Int = 4,
        networkTimeout: TimeInterval = 30,
        cachingEnabled: Bool = true,
        maxCacheSize: Int = 100,
        maxTextLength: Int = 0,
        maxKeywords: Int = 10,
        userAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    ) {
        self.maxConcurrency = max(1, maxConcurrency)
        self.networkTimeout = max(1, networkTimeout)
        self.cachingEnabled = cachingEnabled
        self.maxCacheSize = max(1, maxCacheSize)
        self.maxTextLength = max(0, maxTextLength)
        self.maxKeywords = max(1, maxKeywords)
        self.userAgent = userAgent
    }
}
