import XCTest
@testable import Juicer

final class WeiboExtractorTests: XCTestCase {

    let extractor = WeiboExtractor()

    // MARK: - canExtract

    func testCanExtractFromWeiboURL() {
        XCTAssertTrue(extractor.canExtract(from: .url("https://weibo.com/1234567890/abc")))
        XCTAssertTrue(extractor.canExtract(from: .url("https://www.weibo.com/1234567890/abc")))
        XCTAssertTrue(extractor.canExtract(from: .url("https://m.weibo.cn/detail/123456")))
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

    // MARK: - HTML Parsing

    func testParseWeiboHTML() {
        let html = """
        <html>
        <head>
            <meta property="og:title" content="微博用户发布了一条微博">
            <meta property="og:description" content="今天天气真好，出去玩了一天">
            <meta property="og:image" content="https://img.weibo.com/photo1.jpg">
            <meta property="og:video" content="https://video.weibo.com/v.mp4">
            <meta name="author" content="微博用户">
        </head>
        </html>
        """

        let content = extractor.parseWeiboHTML(html, source: .url("https://weibo.com/123/abc"), url: "https://weibo.com/123/abc")

        XCTAssertEqual(content.contentType, .weiboLink)
        XCTAssertEqual(content.title, "微博用户发布了一条微博")
        XCTAssertEqual(content.textContent, "今天天气真好，出去玩了一天")
        XCTAssertEqual(content.imageURLs, ["https://img.weibo.com/photo1.jpg"])
        XCTAssertEqual(content.videoURLs, ["https://video.weibo.com/v.mp4"])
        XCTAssertEqual(content.author, "微博用户")
        XCTAssertEqual(content.metadata["platform"], "weibo")
    }

    func testParseWeiboHTMLMultipleImages() {
        let html = """
        <html>
        <head>
            <meta property="og:title" content="照片集">
            <meta property="og:image" content="https://img1.jpg">
            <meta property="og:image" content="https://img2.jpg">
            <meta property="og:image" content="https://img3.jpg">
        </head>
        </html>
        """

        let content = extractor.parseWeiboHTML(html, source: .url("https://weibo.com/123/abc"), url: "https://weibo.com/123/abc")

        XCTAssertEqual(content.imageURLs.count, 3)
    }

    func testUnsupportedSourceThrows() async {
        do {
            _ = try await extractor.extract(from: .text("not a weibo URL"))
            XCTFail("Expected error for unsupported source")
        } catch {
            XCTAssertTrue(error is ExtractionError)
        }
    }
}
