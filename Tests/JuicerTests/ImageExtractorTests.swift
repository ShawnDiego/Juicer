import XCTest
@testable import Juicer

final class ImageExtractorTests: XCTestCase {

    let extractor = ImageExtractor()

    func testCanExtractFromImageData() {
        XCTAssertTrue(extractor.canExtract(from: .imageData(Data(), filename: "test.jpg")))
    }

    func testCanExtractFromImageFileURL() {
        let url = URL(fileURLWithPath: "/tmp/photo.png")
        XCTAssertTrue(extractor.canExtract(from: .fileURL(url)))
    }

    func testCannotExtractFromVideoFileURL() {
        let url = URL(fileURLWithPath: "/tmp/clip.mp4")
        XCTAssertFalse(extractor.canExtract(from: .fileURL(url)))
    }

    func testCannotExtractFromText() {
        XCTAssertFalse(extractor.canExtract(from: .text("hello")))
    }

    func testExtractFromImageData() async throws {
        let data = Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0x00, 0x00, 0x00]) // PNG header
        let content = try await extractor.extract(from: .imageData(data, filename: "test.png"))

        XCTAssertEqual(content.contentType, .image)
        XCTAssertEqual(content.title, "test.png")
        XCTAssertEqual(content.metadata["imageFormat"], "PNG")
        XCTAssertEqual(content.metadata["filename"], "test.png")
        XCTAssertNotNil(content.metadata["fileSize"])
    }

    func testDetectJPEGFormat() {
        let data = Data([0xFF, 0xD8, 0xFF, 0xE0])
        XCTAssertEqual(extractor.detectImageFormat(data), "JPEG")
    }

    func testDetectPNGFormat() {
        let data = Data([0x89, 0x50, 0x4E, 0x47])
        XCTAssertEqual(extractor.detectImageFormat(data), "PNG")
    }

    func testDetectGIFFormat() {
        let data = Data([0x47, 0x49, 0x46, 0x38])
        XCTAssertEqual(extractor.detectImageFormat(data), "GIF")
    }

    func testDetectBMPFormat() {
        let data = Data([0x42, 0x4D, 0x00, 0x00])
        XCTAssertEqual(extractor.detectImageFormat(data), "BMP")
    }

    func testDetectUnknownFormat() {
        let data = Data([0x00, 0x00, 0x00, 0x00])
        XCTAssertNil(extractor.detectImageFormat(data))
    }

    func testDetectTooShortData() {
        let data = Data([0xFF])
        XCTAssertNil(extractor.detectImageFormat(data))
    }

    func testUnsupportedSourceThrows() async {
        do {
            _ = try await extractor.extract(from: .text("not an image"))
            XCTFail("Expected error for unsupported source")
        } catch {
            XCTAssertTrue(error is ExtractionError)
        }
    }
}
