import XCTest
@testable import Juicer

final class JuicerTests: XCTestCase {

    func testProcessPlainText() async throws {
        let juicer = Juicer()
        let result = try await juicer.process(input: "这是一段简单的测试文字，用来验证Juicer的基本功能。")

        XCTAssertEqual(result.extractedContent.contentType, .text)
        XCTAssertFalse(result.summary.isEmpty)
        XCTAssertTrue(result.wordCount > 0)
    }

    func testProcessImageData() async throws {
        let juicer = Juicer()
        let pngData = Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0x00, 0x00, 0x00])
        let result = try await juicer.process(source: .imageData(pngData, filename: "test.png"))

        XCTAssertEqual(result.extractedContent.contentType, .image)
        XCTAssertEqual(result.extractedContent.metadata["imageFormat"], "PNG")
    }

    func testProcessVideoData() async throws {
        let juicer = Juicer()
        var mp4Data = Data(repeating: 0x00, count: 12)
        mp4Data[4] = 0x66; mp4Data[5] = 0x74; mp4Data[6] = 0x79; mp4Data[7] = 0x70
        let result = try await juicer.process(source: .videoData(mp4Data, filename: "test.mp4"))

        XCTAssertEqual(result.extractedContent.contentType, .video)
        XCTAssertEqual(result.extractedContent.metadata["videoFormat"], "MP4")
    }

    func testExtractPlainText() async throws {
        let juicer = Juicer()
        let content = try await juicer.extract(input: "Hello Juicer!")

        XCTAssertEqual(content.contentType, .text)
        XCTAssertEqual(content.textContent, "Hello Juicer!")
    }

    func testExtractImageSource() async throws {
        let juicer = Juicer()
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x00, 0x00, 0x00])
        let content = try await juicer.extract(source: .imageData(jpegData, filename: "photo.jpg"))

        XCTAssertEqual(content.contentType, .image)
        XCTAssertEqual(content.metadata["imageFormat"], "JPEG")
    }

    func testDouyinLinkDetectionInProcess() async throws {
        // This test verifies that Douyin URLs are detected correctly in the pipeline.
        // The actual network fetch will fail in test, so we just verify detection.
        let (type, _) = LinkDetector().detect("Check this https://v.douyin.com/abc123")
        XCTAssertEqual(type, .douyinLink)

        // Verify XHS detection too
        let (type2, _) = LinkDetector().detect("看看 https://www.xiaohongshu.com/explore/123 这个")
        XCTAssertEqual(type2, .xiaohongshuLink)
    }

    func testHTMLParsingHelpers() {
        let html = """
        <html>
        <head>
            <title>Test Page</title>
            <meta property="og:title" content="OG Title">
            <meta property="og:description" content="OG Description">
            <meta name="author" content="Test Author">
        </head>
        </html>
        """

        XCTAssertEqual(extractMetaContent(from: html, property: "og:title"), "OG Title")
        XCTAssertEqual(extractMetaContent(from: html, property: "og:description"), "OG Description")
        XCTAssertEqual(extractMetaContent(from: html, name: "author"), "Test Author")
        XCTAssertEqual(extractTag(from: html, tag: "title"), "Test Page")
    }

    func testDouyinHTMLParsing() {
        let extractor = DouyinExtractor()
        let html = """
        <html>
        <head>
            <meta property="og:title" content="测试视频标题">
            <meta property="og:description" content="这是一个测试视频描述">
            <meta property="og:image" content="https://img.example.com/thumb.jpg">
            <meta property="og:video" content="https://video.example.com/v.mp4">
        </head>
        </html>
        """

        let content = extractor.parseDouyinHTML(html, source: .url("https://v.douyin.com/abc"), url: "https://v.douyin.com/abc")

        XCTAssertEqual(content.title, "测试视频标题")
        XCTAssertEqual(content.textContent, "这是一个测试视频描述")
        XCTAssertEqual(content.imageURLs, ["https://img.example.com/thumb.jpg"])
        XCTAssertEqual(content.videoURLs, ["https://video.example.com/v.mp4"])
        XCTAssertEqual(content.metadata["platform"], "douyin")
    }

    func testXiaohongshuHTMLParsing() {
        let extractor = XiaohongshuExtractor()
        let html = """
        <html>
        <head>
            <meta property="og:title" content="小红书笔记标题">
            <meta property="og:description" content="这是小红书笔记内容">
            <meta property="og:image" content="https://img.example.com/xhs1.jpg">
            <meta name="author" content="TestUser">
        </head>
        </html>
        """

        let content = extractor.parseXiaohongshuHTML(html, source: .url("https://www.xiaohongshu.com/explore/123"), url: "https://www.xiaohongshu.com/explore/123")

        XCTAssertEqual(content.title, "小红书笔记标题")
        XCTAssertEqual(content.textContent, "这是小红书笔记内容")
        XCTAssertEqual(content.author, "TestUser")
        XCTAssertEqual(content.metadata["platform"], "xiaohongshu")
    }

    // MARK: - Weibo Integration

    func testWeiboLinkDetectionInProcess() {
        let (type, _) = LinkDetector().detect("看看这条微博 https://weibo.com/123/abc 有趣吗")
        XCTAssertEqual(type, .weiboLink)
    }

    func testWeiboHTMLParsing() {
        let extractor = WeiboExtractor()
        let html = """
        <html>
        <head>
            <meta property="og:title" content="微博帖子标题">
            <meta property="og:description" content="这是一条微博内容">
            <meta property="og:image" content="https://img.weibo.com/photo.jpg">
            <meta name="author" content="WeiboUser">
        </head>
        </html>
        """

        let content = extractor.parseWeiboHTML(html, source: .url("https://weibo.com/123/abc"), url: "https://weibo.com/123/abc")

        XCTAssertEqual(content.title, "微博帖子标题")
        XCTAssertEqual(content.textContent, "这是一条微博内容")
        XCTAssertEqual(content.author, "WeiboUser")
        XCTAssertEqual(content.metadata["platform"], "weibo")
    }

    // MARK: - Error Equatable

    func testExtractionErrorEquatable() {
        XCTAssertEqual(ExtractionError.unsupportedSource, ExtractionError.unsupportedSource)
        XCTAssertEqual(ExtractionError.noContentFound, ExtractionError.noContentFound)
        XCTAssertEqual(ExtractionError.invalidURL("test"), ExtractionError.invalidURL("test"))
        XCTAssertEqual(ExtractionError.textTooLong(100), ExtractionError.textTooLong(100))
        XCTAssertNotEqual(ExtractionError.invalidURL("a"), ExtractionError.invalidURL("b"))
        XCTAssertNotEqual(ExtractionError.unsupportedSource, ExtractionError.noContentFound)
    }

    func testAnalysisErrorEquatable() {
        XCTAssertEqual(AnalysisError.emptyContent, AnalysisError.emptyContent)
        XCTAssertEqual(AnalysisError.analysisUnavailable("a"), AnalysisError.analysisUnavailable("a"))
        XCTAssertNotEqual(AnalysisError.emptyContent, AnalysisError.analysisUnavailable("x"))
    }
}
