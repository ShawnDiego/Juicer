import XCTest
@testable import Juicer

final class DouyinExtractorTests: XCTestCase {

    let extractor = DouyinExtractor()

    // MARK: - canExtract

    func testCanExtractFromDouyinURL() {
        XCTAssertTrue(extractor.canExtract(from: .url("https://v.douyin.com/iRN2abc/")))
        XCTAssertTrue(extractor.canExtract(from: .url("https://www.douyin.com/video/7234567890123456789")))
        XCTAssertTrue(extractor.canExtract(from: .url("https://douyin.com/video/7234567890123456789")))
        XCTAssertTrue(extractor.canExtract(from: .url("https://www.iesdouyin.com/share/video/123")))
    }

    func testCannotExtractFromOtherSources() {
        XCTAssertFalse(extractor.canExtract(from: .url("https://www.xiaohongshu.com/explore/123")))
        XCTAssertFalse(extractor.canExtract(from: .url("https://weibo.com/123/abc")))
        XCTAssertFalse(extractor.canExtract(from: .url("https://example.com")))
        XCTAssertFalse(extractor.canExtract(from: .text("hello")))
        XCTAssertFalse(extractor.canExtract(from: .imageData(Data(), filename: nil)))
    }

    // MARK: - Video ID Extraction

    func testExtractVideoIdFromVideoURL() {
        XCTAssertEqual(
            DouyinExtractor.extractVideoId(from: "https://www.douyin.com/video/7234567890123456789"),
            "7234567890123456789"
        )
    }

    func testExtractVideoIdFromVideoURLWithQuery() {
        XCTAssertEqual(
            DouyinExtractor.extractVideoId(from: "https://www.douyin.com/video/7234567890123456789?previous_page=web_code_link"),
            "7234567890123456789"
        )
    }

    func testExtractVideoIdReturnsNilForNonVideoURL() {
        XCTAssertNil(DouyinExtractor.extractVideoId(from: "https://v.douyin.com/iRN2abc/"))
        XCTAssertNil(DouyinExtractor.extractVideoId(from: "https://www.douyin.com/user/MS4wLjABAAAAxxx"))
        XCTAssertNil(DouyinExtractor.extractVideoId(from: "https://example.com"))
    }

    // MARK: - Note ID Extraction

    func testExtractNoteIdFromNoteURL() {
        XCTAssertEqual(
            DouyinExtractor.extractNoteId(from: "https://www.douyin.com/note/7234567890123456789"),
            "7234567890123456789"
        )
    }

    func testExtractNoteIdReturnsNilForNonNoteURL() {
        XCTAssertNil(DouyinExtractor.extractNoteId(from: "https://www.douyin.com/video/7234567890123456789"))
        XCTAssertNil(DouyinExtractor.extractNoteId(from: "https://v.douyin.com/iRN2abc/"))
    }

    // MARK: - HTML Parsing with Resolved URL

    func testParseDouyinHTMLWithResolvedURL() {
        let html = """
        <html>
        <head>
            <meta property="og:title" content="测试视频标题">
            <meta property="og:description" content="这是一个测试视频描述">
            <meta property="og:image" content="https://img.example.com/thumb.jpg">
            <meta property="og:video" content="https://video.example.com/v.mp4">
            <meta property="og:author" content="测试作者">
        </head>
        </html>
        """

        let content = extractor.parseDouyinHTML(
            html,
            source: .url("https://v.douyin.com/iRN2abc/"),
            url: "https://v.douyin.com/iRN2abc/",
            resolvedURL: "https://www.douyin.com/video/7234567890123456789"
        )

        XCTAssertEqual(content.contentType, .douyinLink)
        XCTAssertEqual(content.title, "测试视频标题")
        XCTAssertEqual(content.textContent, "这是一个测试视频描述")
        XCTAssertEqual(content.imageURLs, ["https://img.example.com/thumb.jpg"])
        XCTAssertEqual(content.videoURLs, ["https://video.example.com/v.mp4"])
        XCTAssertEqual(content.author, "测试作者")
        XCTAssertEqual(content.metadata["platform"], "douyin")
        XCTAssertEqual(content.metadata["originalURL"], "https://v.douyin.com/iRN2abc/")
        XCTAssertEqual(content.metadata["resolvedURL"], "https://www.douyin.com/video/7234567890123456789")
        XCTAssertEqual(content.metadata["videoId"], "7234567890123456789")
        XCTAssertEqual(content.metadata["contentSubtype"], "video")
    }

    func testParseDouyinHTMLNoteContent() {
        let html = """
        <html>
        <head>
            <meta property="og:title" content="图文笔记标题">
            <meta property="og:description" content="这是一个图文笔记描述">
            <meta property="og:image" content="https://img.example.com/note1.jpg">
        </head>
        </html>
        """

        let content = extractor.parseDouyinHTML(
            html,
            source: .url("https://v.douyin.com/iRN2abc/"),
            url: "https://v.douyin.com/iRN2abc/",
            resolvedURL: "https://www.douyin.com/note/7234567890123456789"
        )

        XCTAssertEqual(content.metadata["noteId"], "7234567890123456789")
        XCTAssertEqual(content.metadata["contentSubtype"], "note")
        XCTAssertNil(content.metadata["videoId"])
    }

    func testParseDouyinHTMLWithSameOriginalAndResolvedURL() {
        let html = """
        <html>
        <head>
            <meta property="og:title" content="直接访问">
            <meta property="og:video" content="https://video.example.com/v.mp4">
        </head>
        </html>
        """

        let url = "https://www.douyin.com/video/7234567890123456789"
        let content = extractor.parseDouyinHTML(
            html,
            source: .url(url),
            url: url,
            resolvedURL: url
        )

        // resolvedURL should NOT be stored when same as originalURL
        XCTAssertNil(content.metadata["resolvedURL"])
        // videoId should still be extracted
        XCTAssertEqual(content.metadata["videoId"], "7234567890123456789")
    }

    // MARK: - ExtractedContent Convenience Properties

    func testDownloadURLReturnsVideoURL() {
        let content = ExtractedContent(
            contentType: .douyinLink,
            source: .url("https://v.douyin.com/abc"),
            videoURLs: ["https://video.example.com/v.mp4"]
        )
        XCTAssertEqual(content.downloadURL, "https://video.example.com/v.mp4")
    }

    func testDownloadURLReturnsImageURLWhenNoVideo() {
        let content = ExtractedContent(
            contentType: .douyinLink,
            source: .url("https://v.douyin.com/abc"),
            imageURLs: ["https://img.example.com/photo.jpg"]
        )
        XCTAssertEqual(content.downloadURL, "https://img.example.com/photo.jpg")
    }

    func testDownloadURLReturnsNilWhenNoMedia() {
        let content = ExtractedContent(
            contentType: .text,
            source: .text("hello"),
            textContent: "hello"
        )
        XCTAssertNil(content.downloadURL)
    }

    func testDownloadURLPrefersVideoOverImage() {
        let content = ExtractedContent(
            contentType: .douyinLink,
            source: .url("https://v.douyin.com/abc"),
            imageURLs: ["https://img.example.com/photo.jpg"],
            videoURLs: ["https://video.example.com/v.mp4"]
        )
        XCTAssertEqual(content.downloadURL, "https://video.example.com/v.mp4")
    }

    func testResolvedURLProperty() {
        let content = ExtractedContent(
            contentType: .douyinLink,
            source: .url("https://v.douyin.com/abc"),
            metadata: ["resolvedURL": "https://www.douyin.com/video/123"]
        )
        XCTAssertEqual(content.resolvedURL, "https://www.douyin.com/video/123")
    }

    func testContentIdFromVideoId() {
        let content = ExtractedContent(
            contentType: .douyinLink,
            source: .url("https://v.douyin.com/abc"),
            metadata: ["videoId": "7234567890123456789"]
        )
        XCTAssertEqual(content.contentId, "7234567890123456789")
    }

    func testContentIdFromNoteId() {
        let content = ExtractedContent(
            contentType: .douyinLink,
            source: .url("https://v.douyin.com/abc"),
            metadata: ["noteId": "7234567890123456789"]
        )
        XCTAssertEqual(content.contentId, "7234567890123456789")
    }

    // MARK: - Share Text Detection

    func testDetectDouyinShareText() {
        let detector = LinkDetector()

        // Typical Douyin share text
        let shareText = "7.29 PJu:/ 复制打开抖音，看看【测试用户的作品】一起在抖音发现更多创意！ https://v.douyin.com/iRN2abc/"
        let (type, url) = detector.detect(shareText)
        XCTAssertEqual(type, .douyinLink)
        XCTAssertEqual(url, "https://v.douyin.com/iRN2abc/")
    }

    func testDetectDouyinShareTextWithChineseAroundLink() {
        let detector = LinkDetector()

        let shareText = "在抖音发现了一个好看的视频 https://v.douyin.com/abc123 快来看看吧！"
        let (type, url) = detector.detect(shareText)
        XCTAssertEqual(type, .douyinLink)
        XCTAssertEqual(url, "https://v.douyin.com/abc123")
    }

    func testDetectDouyinDirectVideoURL() {
        let detector = LinkDetector()

        let (type, url) = detector.detect("https://www.douyin.com/video/7234567890123456789")
        XCTAssertEqual(type, .douyinLink)
        XCTAssertEqual(url, "https://www.douyin.com/video/7234567890123456789")
    }

    // MARK: - Unsupported Source

    func testUnsupportedSourceThrows() async {
        do {
            _ = try await extractor.extract(from: .text("not a douyin URL"))
            XCTFail("Expected error for unsupported source")
        } catch {
            XCTAssertTrue(error is ExtractionError)
        }
    }
}
