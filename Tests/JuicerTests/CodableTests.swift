import XCTest
@testable import Juicer

final class CodableTests: XCTestCase {

    // MARK: - ContentSource Codable

    func testContentSourceURLCodable() throws {
        let source = ContentSource.url("https://example.com")
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(ContentSource.self, from: data)

        if case .url(let value) = decoded {
            XCTAssertEqual(value, "https://example.com")
        } else {
            XCTFail("Expected .url case")
        }
    }

    func testContentSourceTextCodable() throws {
        let source = ContentSource.text("Hello World")
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(ContentSource.self, from: data)

        if case .text(let value) = decoded {
            XCTAssertEqual(value, "Hello World")
        } else {
            XCTFail("Expected .text case")
        }
    }

    func testContentSourceImageDataCodable() throws {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let source = ContentSource.imageData(imageData, filename: "test.png")
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(ContentSource.self, from: data)

        if case .imageData(let decodedData, let filename) = decoded {
            XCTAssertEqual(decodedData, imageData)
            XCTAssertEqual(filename, "test.png")
        } else {
            XCTFail("Expected .imageData case")
        }
    }

    func testContentSourceVideoDataCodable() throws {
        let videoData = Data([0x00, 0x00, 0x00, 0x00])
        let source = ContentSource.videoData(videoData, filename: "clip.mp4")
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(ContentSource.self, from: data)

        if case .videoData(let decodedData, let filename) = decoded {
            XCTAssertEqual(decodedData, videoData)
            XCTAssertEqual(filename, "clip.mp4")
        } else {
            XCTFail("Expected .videoData case")
        }
    }

    func testContentSourceFileURLCodable() throws {
        let source = ContentSource.fileURL(URL(fileURLWithPath: "/tmp/test.jpg"))
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(ContentSource.self, from: data)

        if case .fileURL(let url) = decoded {
            XCTAssertEqual(url.path, "/tmp/test.jpg")
        } else {
            XCTFail("Expected .fileURL case")
        }
    }

    func testContentSourceNilFilenameCodable() throws {
        let source = ContentSource.imageData(Data(), filename: nil)
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(ContentSource.self, from: data)

        if case .imageData(_, let filename) = decoded {
            XCTAssertNil(filename)
        } else {
            XCTFail("Expected .imageData case")
        }
    }

    // MARK: - ExtractedContent Codable

    func testExtractedContentCodable() throws {
        let content = ExtractedContent(
            contentType: .text,
            source: .text("hello"),
            title: "Hello",
            textContent: "hello world",
            imageURLs: ["https://img.example.com/photo.jpg"],
            author: "TestUser",
            metadata: ["key": "value"]
        )

        let data = try JSONEncoder().encode(content)
        let decoded = try JSONDecoder().decode(ExtractedContent.self, from: data)

        XCTAssertEqual(decoded.contentType, .text)
        XCTAssertEqual(decoded.title, "Hello")
        XCTAssertEqual(decoded.textContent, "hello world")
        XCTAssertEqual(decoded.imageURLs, ["https://img.example.com/photo.jpg"])
        XCTAssertEqual(decoded.author, "TestUser")
        XCTAssertEqual(decoded.metadata["key"], "value")
    }

    // MARK: - AnalysisResult Codable

    func testAnalysisResultCodable() throws {
        let content = ExtractedContent(
            contentType: .douyinLink,
            source: .url("https://v.douyin.com/abc"),
            title: "Video"
        )
        let result = AnalysisResult(
            extractedContent: content,
            summary: "A video about something",
            keywords: ["video", "test"],
            language: "zh",
            labels: ["douyinLink", "has-video"],
            wordCount: 5,
            hasMedia: true,
            metadata: ["imageCount": "1"]
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(AnalysisResult.self, from: data)

        XCTAssertEqual(decoded.summary, "A video about something")
        XCTAssertEqual(decoded.keywords, ["video", "test"])
        XCTAssertEqual(decoded.language, "zh")
        XCTAssertEqual(decoded.wordCount, 5)
        XCTAssertTrue(decoded.hasMedia)
        XCTAssertEqual(decoded.extractedContent.contentType, .douyinLink)
    }
}
