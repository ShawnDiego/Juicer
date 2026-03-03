import XCTest
@testable import Juicer

final class LinkDetectorTests: XCTestCase {

    let detector = LinkDetector()

    // MARK: - Douyin URL Detection

    func testDetectDouyinURL() {
        XCTAssertTrue(detector.isDouyinURL("https://www.douyin.com/video/123456"))
        XCTAssertTrue(detector.isDouyinURL("https://v.douyin.com/abc123"))
        XCTAssertTrue(detector.isDouyinURL("https://www.iesdouyin.com/share/video/123"))
    }

    func testDetectDouyinURLNegative() {
        XCTAssertFalse(detector.isDouyinURL("https://www.google.com"))
        XCTAssertFalse(detector.isDouyinURL("https://www.xiaohongshu.com/explore/123"))
        XCTAssertFalse(detector.isDouyinURL("not a url"))
    }

    // MARK: - Xiaohongshu URL Detection

    func testDetectXiaohongshuURL() {
        XCTAssertTrue(detector.isXiaohongshuURL("https://www.xiaohongshu.com/explore/123"))
        XCTAssertTrue(detector.isXiaohongshuURL("https://xhslink.com/abc123"))
    }

    func testDetectXiaohongshuURLNegative() {
        XCTAssertFalse(detector.isXiaohongshuURL("https://www.google.com"))
        XCTAssertFalse(detector.isXiaohongshuURL("https://v.douyin.com/abc123"))
        XCTAssertFalse(detector.isXiaohongshuURL("just some text"))
    }

    // MARK: - Input Detection (mixed text)

    func testDetectDouyinLinkInText() {
        let input = "来看看这个视频 https://v.douyin.com/abc123 太好看了！"
        let (type, url) = detector.detect(input)
        XCTAssertEqual(type, .douyinLink)
        XCTAssertEqual(url, "https://v.douyin.com/abc123")
    }

    func testDetectXiaohongshuLinkInText() {
        let input = "我在小红书发现了好东西 https://www.xiaohongshu.com/explore/abc123 快来看"
        let (type, url) = detector.detect(input)
        XCTAssertEqual(type, .xiaohongshuLink)
        XCTAssertTrue(url.contains("xiaohongshu.com"))
    }

    func testDetectPlainText() {
        let input = "这是一段普通的文字，没有任何链接。"
        let (type, text) = detector.detect(input)
        XCTAssertEqual(type, .text)
        XCTAssertEqual(text, input)
    }

    func testDetectEmptyInput() {
        let (type, text) = detector.detect("")
        XCTAssertEqual(type, .text)
        XCTAssertEqual(text, "")
    }

    // MARK: - URL Extraction

    func testExtractURLsFromText() {
        let text = "Visit https://example.com and https://google.com today"
        let urls = detector.extractURLs(from: text)
        XCTAssertEqual(urls.count, 2)
    }

    func testExtractNoURLs() {
        let urls = detector.extractURLs(from: "no urls here")
        XCTAssertTrue(urls.isEmpty)
    }

    // MARK: - URL Classification

    func testClassifyDouyinURL() {
        XCTAssertEqual(detector.classifyURL("https://v.douyin.com/abc"), .douyinLink)
    }

    func testClassifyXiaohongshuURL() {
        XCTAssertEqual(detector.classifyURL("https://www.xiaohongshu.com/explore/123"), .xiaohongshuLink)
    }

    func testClassifyUnknownURL() {
        XCTAssertNil(detector.classifyURL("https://example.com"))
    }
}
