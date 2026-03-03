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

    // MARK: - Weibo URL Detection

    func testDetectWeiboURL() {
        XCTAssertTrue(detector.isWeiboURL("https://weibo.com/1234567890/abc"))
        XCTAssertTrue(detector.isWeiboURL("https://www.weibo.com/1234567890/abc"))
        XCTAssertTrue(detector.isWeiboURL("https://m.weibo.cn/detail/123456"))
        XCTAssertTrue(detector.isWeiboURL("https://weibo.cn/detail/123456"))
    }

    func testDetectWeiboURLNegative() {
        XCTAssertFalse(detector.isWeiboURL("https://www.google.com"))
        XCTAssertFalse(detector.isWeiboURL("https://v.douyin.com/abc123"))
        XCTAssertFalse(detector.isWeiboURL("not a url"))
    }

    func testDetectWeiboLinkInText() {
        let input = "看看这条微博 https://weibo.com/1234567890/abc 太有意思了！"
        let (type, url) = detector.detect(input)
        XCTAssertEqual(type, .weiboLink)
        XCTAssertTrue(url.contains("weibo.com"))
    }

    func testClassifyWeiboURL() {
        XCTAssertEqual(detector.classifyURL("https://weibo.com/123/abc"), .weiboLink)
        XCTAssertEqual(detector.classifyURL("https://m.weibo.cn/detail/123"), .weiboLink)
    }

    // MARK: - Generic URL Detection

    func testIsGenericURL() {
        XCTAssertTrue(detector.isGenericURL("https://example.com/article"))
        XCTAssertTrue(detector.isGenericURL("http://blog.example.org/post"))
    }

    func testIsGenericURLNegative() {
        XCTAssertFalse(detector.isGenericURL("not a url"))
        XCTAssertFalse(detector.isGenericURL("ftp://files.example.com/data"))
        XCTAssertFalse(detector.isGenericURL(""))
    }
}
