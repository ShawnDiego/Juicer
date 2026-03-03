import Foundation

/// A thread-safe in-memory cache for extracted content and analysis results.
///
/// Uses an LRU eviction policy when the cache exceeds its maximum size.
public final class ContentCache: @unchecked Sendable {

    private let lock = NSLock()
    private var extractionCache: [String: CacheEntry<ExtractedContent>] = [:]
    private var analysisCache: [String: CacheEntry<AnalysisResult>] = [:]
    private let maxSize: Int

    /// Creates a new cache with the specified maximum number of entries per type.
    public init(maxSize: Int = 100) {
        self.maxSize = max(1, maxSize)
    }

    // MARK: - Extraction Cache

    /// Returns a cached `ExtractedContent` for the given key, or `nil` if not found.
    public func getExtraction(for key: String) -> ExtractedContent? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = extractionCache[key] else { return nil }
        extractionCache[key] = CacheEntry(value: entry.value, accessedAt: Date())
        return entry.value
    }

    /// Stores an `ExtractedContent` in the cache.
    public func setExtraction(_ content: ExtractedContent, for key: String) {
        lock.lock()
        defer { lock.unlock() }
        extractionCache[key] = CacheEntry(value: content, accessedAt: Date())
        evictIfNeeded(&extractionCache)
    }

    // MARK: - Analysis Cache

    /// Returns a cached `AnalysisResult` for the given key, or `nil` if not found.
    public func getAnalysis(for key: String) -> AnalysisResult? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = analysisCache[key] else { return nil }
        analysisCache[key] = CacheEntry(value: entry.value, accessedAt: Date())
        return entry.value
    }

    /// Stores an `AnalysisResult` in the cache.
    public func setAnalysis(_ result: AnalysisResult, for key: String) {
        lock.lock()
        defer { lock.unlock() }
        analysisCache[key] = CacheEntry(value: result, accessedAt: Date())
        evictIfNeeded(&analysisCache)
    }

    // MARK: - Management

    /// Removes all entries from the cache.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        extractionCache.removeAll()
        analysisCache.removeAll()
    }

    /// The current number of extraction cache entries.
    public var extractionCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return extractionCache.count
    }

    /// The current number of analysis cache entries.
    public var analysisCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return analysisCache.count
    }

    // MARK: - Private

    private struct CacheEntry<T> {
        let value: T
        let accessedAt: Date
    }

    private func evictIfNeeded<T>(_ cache: inout [String: CacheEntry<T>]) {
        guard cache.count > maxSize else { return }
        // Evict the least recently accessed entry
        if let oldest = cache.min(by: { $0.value.accessedAt < $1.value.accessedAt }) {
            cache.removeValue(forKey: oldest.key)
        }
    }

    /// Generates a cache key from a `ContentSource`.
    public static func cacheKey(for source: ContentSource) -> String {
        switch source {
        case .url(let urlString):
            return "url:\(urlString)"
        case .text(let text):
            return "text:\(text.hashValue)"
        case .imageData(let data, let filename):
            return "image:\(data.hashValue):\(filename ?? "unknown")"
        case .videoData(let data, let filename):
            return "video:\(data.hashValue):\(filename ?? "unknown")"
        case .fileURL(let url):
            return "file:\(url.path)"
        }
    }
}
