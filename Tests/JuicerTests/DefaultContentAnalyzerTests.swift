import XCTest
@testable import Juicer

final class DefaultContentAnalyzerTests: XCTestCase {

    let analyzer = DefaultContentAnalyzer()

    func testAnalyzeTextContent() async throws {
        let content = ExtractedContent(
            contentType: .text,
            source: .text("Hello world, this is a test of the content analyzer."),
            title: "Hello World",
            textContent: "Hello world, this is a test of the content analyzer."
        )

        let result = try await analyzer.analyze(content)

        XCTAssertFalse(result.summary.isEmpty)
        XCTAssertTrue(result.wordCount > 0)
        XCTAssertFalse(result.hasMedia)
        XCTAssertTrue(result.labels.contains("text"))
    }

    func testAnalyzeContentWithMedia() async throws {
        let content = ExtractedContent(
            contentType: .douyinLink,
            source: .url("https://v.douyin.com/abc"),
            title: "Douyin Video",
            textContent: "这是一个很棒的视频",
            imageURLs: ["https://img.example.com/thumb.jpg"],
            videoURLs: ["https://video.example.com/v.mp4"]
        )

        let result = try await analyzer.analyze(content)

        XCTAssertTrue(result.hasMedia)
        XCTAssertTrue(result.labels.contains("has-images"))
        XCTAssertTrue(result.labels.contains("has-video"))
        XCTAssertEqual(result.metadata["imageCount"], "1")
        XCTAssertEqual(result.metadata["videoCount"], "1")
    }

    func testAnalyzeEmptyContentThrows() async {
        let content = ExtractedContent(
            contentType: .text,
            source: .text(""),
            title: nil,
            textContent: nil
        )

        do {
            _ = try await analyzer.analyze(content)
            XCTFail("Expected error for empty content")
        } catch {
            XCTAssertTrue(error is AnalysisError)
        }
    }

    func testDetectChineseLanguage() {
        let language = analyzer.detectLanguage("这是一段中文测试文字")
        XCTAssertEqual(language, "zh")
    }

    func testDetectEnglishLanguage() {
        let language = analyzer.detectLanguage("This is an English test string")
        XCTAssertEqual(language, "en")
    }

    func testKeywordExtraction() {
        let keywords = analyzer.extractKeywords(from: "swift programming language swift development swift tools")
        XCTAssertTrue(keywords.contains("swift"))
        XCTAssertTrue(keywords.contains("programming"))
    }

    func testKeywordExtractionFiltersStopWords() {
        let keywords = analyzer.extractKeywords(from: "the quick brown fox is a very fast animal")
        XCTAssertFalse(keywords.contains("the"))
        XCTAssertFalse(keywords.contains("is"))
        XCTAssertFalse(keywords.contains("very"))
    }

    func testWordCount() {
        XCTAssertEqual(analyzer.countWords(in: "one two three"), 3)
        XCTAssertEqual(analyzer.countWords(in: ""), 0)
        XCTAssertEqual(analyzer.countWords(in: "single"), 1)
    }

    func testLabelsIncludeContentType() {
        let labels = analyzer.generateLabels(for: ExtractedContent(
            contentType: .xiaohongshuLink,
            source: .url("https://www.xiaohongshu.com/explore/123"),
            author: "TestUser"
        ))
        XCTAssertTrue(labels.contains("xiaohongshuLink"))
        XCTAssertTrue(labels.contains("has-author"))
    }

    // MARK: - Hashtag Extraction

    func testExtractHashtags() {
        let hashtags = analyzer.extractHashtags(from: "今天去了#北京 和 #上海旅行 真开心 #travel")
        XCTAssertTrue(hashtags.contains("北京"))
        XCTAssertTrue(hashtags.contains("上海旅行"))
        XCTAssertTrue(hashtags.contains("travel"))
    }

    func testExtractHashtagsEmpty() {
        let hashtags = analyzer.extractHashtags(from: "no hashtags here")
        XCTAssertTrue(hashtags.isEmpty)
    }

    func testExtractHashtagsEmptyString() {
        let hashtags = analyzer.extractHashtags(from: "")
        XCTAssertTrue(hashtags.isEmpty)
    }

    // MARK: - Mention Extraction

    func testExtractMentions() {
        let mentions = analyzer.extractMentions(from: "感谢 @张三 和 @李四 的帮助 @john_doe")
        XCTAssertTrue(mentions.contains("张三"))
        XCTAssertTrue(mentions.contains("李四"))
        XCTAssertTrue(mentions.contains("john_doe"))
    }

    func testExtractMentionsEmpty() {
        let mentions = analyzer.extractMentions(from: "no mentions here")
        XCTAssertTrue(mentions.isEmpty)
    }

    func testExtractMentionsEmptyString() {
        let mentions = analyzer.extractMentions(from: "")
        XCTAssertTrue(mentions.isEmpty)
    }

    // MARK: - Analyzer with Hashtags and Mentions

    func testAnalyzeContentWithHashtagsAndMentions() async throws {
        let content = ExtractedContent(
            contentType: .text,
            source: .text("#旅行日记 今天在北京 @小红薯 推荐的餐厅吃饭"),
            title: "旅行日记",
            textContent: "#旅行日记 今天在北京 @小红薯 推荐的餐厅吃饭"
        )

        let result = try await analyzer.analyze(content)

        XCTAssertNotNil(result.metadata["hashtags"])
        XCTAssertTrue(result.metadata["hashtags"]?.contains("旅行日记") == true)
        XCTAssertNotNil(result.metadata["mentions"])
        XCTAssertTrue(result.metadata["mentions"]?.contains("小红薯") == true)
    }
}
