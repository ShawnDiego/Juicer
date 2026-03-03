import XCTest
@testable import Juicer

final class BatchProcessingTests: XCTestCase {

    func testProcessAllStrings() async {
        let juicer = Juicer()
        let inputs = [
            "Hello World",
            "这是一段中文测试",
            "Another English text for testing"
        ]

        let results = await juicer.processAll(inputs: inputs)

        XCTAssertEqual(results.count, 3)
        for result in results {
            XCTAssertNotNil(result, "Each text input should produce a result")
            XCTAssertFalse(result!.summary.isEmpty)
        }
    }

    func testProcessAllSources() async {
        let juicer = Juicer()
        let sources: [ContentSource] = [
            .text("Hello World"),
            .imageData(Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0x00, 0x00, 0x00]), filename: "test.png"),
            .text("More text to process")
        ]

        let results = await juicer.processAll(sources: sources)

        XCTAssertEqual(results.count, 3)
        XCTAssertNotNil(results[0])
        XCTAssertNotNil(results[1])
        XCTAssertNotNil(results[2])
        XCTAssertEqual(results[0]?.extractedContent.contentType, .text)
        XCTAssertEqual(results[1]?.extractedContent.contentType, .image)
    }

    func testProcessAllPreservesOrder() async {
        let juicer = Juicer()
        let inputs = ["First", "Second", "Third"]

        let results = await juicer.processAll(inputs: inputs)

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0]?.extractedContent.textContent, "First")
        XCTAssertEqual(results[1]?.extractedContent.textContent, "Second")
        XCTAssertEqual(results[2]?.extractedContent.textContent, "Third")
    }

    func testProcessAllEmptyInput() async {
        let juicer = Juicer()
        let results = await juicer.processAll(inputs: [])
        XCTAssertTrue(results.isEmpty)
    }
}
