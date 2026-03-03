import XCTest
@testable import Juicer

final class ContentCacheTests: XCTestCase {

    func testSetAndGetExtraction() {
        let cache = ContentCache(maxSize: 10)
        let content = ExtractedContent(
            contentType: .text,
            source: .text("hello"),
            title: "Hello",
            textContent: "hello"
        )

        cache.setExtraction(content, for: "key1")

        let retrieved = cache.getExtraction(for: "key1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Hello")
    }

    func testSetAndGetAnalysis() {
        let cache = ContentCache(maxSize: 10)
        let content = ExtractedContent(
            contentType: .text,
            source: .text("hello"),
            title: "Hello"
        )
        let result = AnalysisResult(
            extractedContent: content,
            summary: "Test summary",
            keywords: ["hello"],
            wordCount: 1
        )

        cache.setAnalysis(result, for: "key1")

        let retrieved = cache.getAnalysis(for: "key1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.summary, "Test summary")
    }

    func testCacheMiss() {
        let cache = ContentCache(maxSize: 10)
        XCTAssertNil(cache.getExtraction(for: "nonexistent"))
        XCTAssertNil(cache.getAnalysis(for: "nonexistent"))
    }

    func testClear() {
        let cache = ContentCache(maxSize: 10)
        let content = ExtractedContent(contentType: .text, source: .text("hi"))

        cache.setExtraction(content, for: "key1")
        cache.setExtraction(content, for: "key2")
        XCTAssertEqual(cache.extractionCount, 2)

        cache.clear()
        XCTAssertEqual(cache.extractionCount, 0)
        XCTAssertEqual(cache.analysisCount, 0)
    }

    func testEvictionWhenMaxSizeExceeded() {
        let cache = ContentCache(maxSize: 2)
        let content1 = ExtractedContent(contentType: .text, source: .text("a"), title: "A")
        let content2 = ExtractedContent(contentType: .text, source: .text("b"), title: "B")
        let content3 = ExtractedContent(contentType: .text, source: .text("c"), title: "C")

        cache.setExtraction(content1, for: "key1")
        cache.setExtraction(content2, for: "key2")
        cache.setExtraction(content3, for: "key3")

        // Cache should have evicted the oldest entry, keeping at most 2
        XCTAssertTrue(cache.extractionCount <= 2)
    }

    func testCacheKeyGeneration() {
        let urlKey = ContentCache.cacheKey(for: .url("https://example.com"))
        XCTAssertTrue(urlKey.hasPrefix("url:"))

        let textKey = ContentCache.cacheKey(for: .text("hello"))
        XCTAssertTrue(textKey.hasPrefix("text:"))

        let imageKey = ContentCache.cacheKey(for: .imageData(Data(), filename: "test.png"))
        XCTAssertTrue(imageKey.hasPrefix("image:"))

        let videoKey = ContentCache.cacheKey(for: .videoData(Data(), filename: "test.mp4"))
        XCTAssertTrue(videoKey.hasPrefix("video:"))

        let fileKey = ContentCache.cacheKey(for: .fileURL(URL(fileURLWithPath: "/tmp/file.txt")))
        XCTAssertTrue(fileKey.hasPrefix("file:"))
    }
}
