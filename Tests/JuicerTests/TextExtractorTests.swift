import XCTest
@testable import Juicer

final class TextExtractorTests: XCTestCase {

    let extractor = TextExtractor()

    func testCanExtractFromText() {
        XCTAssertTrue(extractor.canExtract(from: .text("hello")))
    }

    func testCannotExtractFromURL() {
        XCTAssertFalse(extractor.canExtract(from: .url("https://example.com")))
    }

    func testCannotExtractFromImageData() {
        XCTAssertFalse(extractor.canExtract(from: .imageData(Data(), filename: nil)))
    }

    func testExtractBasicText() async throws {
        let content = try await extractor.extract(from: .text("Hello World"))
        XCTAssertEqual(content.contentType, .text)
        XCTAssertEqual(content.textContent, "Hello World")
        XCTAssertEqual(content.title, "Hello World")
        XCTAssertNotNil(content.metadata["characterCount"])
        XCTAssertNotNil(content.metadata["lineCount"])
    }

    func testExtractMultilineText() async throws {
        let text = "First line\nSecond line\nThird line"
        let content = try await extractor.extract(from: .text(text))
        XCTAssertEqual(content.title, "First line")
        XCTAssertEqual(content.metadata["lineCount"], "3")
    }

    func testExtractTextWithEmbeddedURL() async throws {
        let text = "Check this out https://example.com it's great"
        let content = try await extractor.extract(from: .text(text))
        XCTAssertNotNil(content.metadata["embeddedURLs"])
        XCTAssertTrue(content.metadata["embeddedURLs"]?.contains("example.com") == true)
    }

    func testExtractEmptyTextThrows() async {
        do {
            _ = try await extractor.extract(from: .text(""))
            XCTFail("Expected error for empty text")
        } catch {
            XCTAssertTrue(error is ExtractionError)
        }
    }

    func testExtractWhitespaceOnlyTextThrows() async {
        do {
            _ = try await extractor.extract(from: .text("   \n  \t  "))
            XCTFail("Expected error for whitespace-only text")
        } catch {
            XCTAssertTrue(error is ExtractionError)
        }
    }

    func testTitleTruncation() {
        let longLine = String(repeating: "a", count: 100)
        let title = extractor.extractTitle(from: longLine)
        XCTAssertNotNil(title)
        XCTAssertTrue(title!.count <= 80)
        XCTAssertTrue(title!.hasSuffix("..."))
    }

    func testTitleShortLine() {
        let title = extractor.extractTitle(from: "Short title")
        XCTAssertEqual(title, "Short title")
    }
}
