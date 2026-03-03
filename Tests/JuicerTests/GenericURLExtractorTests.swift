import XCTest
@testable import Juicer

final class GenericURLExtractorTests: XCTestCase {

    let extractor = GenericURLExtractor()

    func testCanExtractFromGenericURL() {
        XCTAssertTrue(extractor.canExtract(from: .url("https://example.com/article")))
        XCTAssertTrue(extractor.canExtract(from: .url("https://medium.com/post/123")))
    }

    func testCannotExtractFromDouyinURL() {
        XCTAssertFalse(extractor.canExtract(from: .url("https://v.douyin.com/abc123")))
    }

    func testCannotExtractFromXiaohongshuURL() {
        XCTAssertFalse(extractor.canExtract(from: .url("https://www.xiaohongshu.com/explore/123")))
    }

    func testCannotExtractFromText() {
        XCTAssertFalse(extractor.canExtract(from: .text("hello")))
    }

    func testCannotExtractFromImageData() {
        XCTAssertFalse(extractor.canExtract(from: .imageData(Data(), filename: nil)))
    }

    func testParseHTML() {
        let html = """
        <html>
        <head>
            <title>Article Title</title>
            <meta property="og:title" content="OG Article Title">
            <meta property="og:description" content="Article description here">
            <meta property="og:image" content="https://img.example.com/cover.jpg">
            <meta property="og:site_name" content="Example Blog">
            <meta property="og:type" content="article">
            <meta name="author" content="John Doe">
        </head>
        </html>
        """

        let content = extractor.parseHTML(html, source: .url("https://example.com/article"), url: "https://example.com/article")

        XCTAssertEqual(content.title, "OG Article Title")
        XCTAssertEqual(content.textContent, "Article description here")
        XCTAssertEqual(content.imageURLs, ["https://img.example.com/cover.jpg"])
        XCTAssertEqual(content.author, "John Doe")
        XCTAssertEqual(content.metadata["siteName"], "Example Blog")
        XCTAssertEqual(content.metadata["ogType"], "article")
        XCTAssertEqual(content.metadata["originalURL"], "https://example.com/article")
    }

    func testParseHTMLFallbackToTitleTag() {
        let html = """
        <html>
        <head><title>Fallback Title</title></head>
        </html>
        """

        let content = extractor.parseHTML(html, source: .url("https://example.com"), url: "https://example.com")
        XCTAssertEqual(content.title, "Fallback Title")
    }

    func testParseHTMLEmptyContent() {
        let html = "<html><head></head><body></body></html>"
        let content = extractor.parseHTML(html, source: .url("https://example.com"), url: "https://example.com")

        XCTAssertNil(content.title)
        XCTAssertNil(content.textContent)
        XCTAssertTrue(content.imageURLs.isEmpty)
        XCTAssertTrue(content.videoURLs.isEmpty)
    }

    func testUnsupportedSourceThrows() async {
        do {
            _ = try await extractor.extract(from: .text("not a url"))
            XCTFail("Expected error for unsupported source")
        } catch {
            XCTAssertTrue(error is ExtractionError)
        }
    }
}
