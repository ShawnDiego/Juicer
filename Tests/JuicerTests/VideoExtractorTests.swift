import XCTest
@testable import Juicer

final class VideoExtractorTests: XCTestCase {

    let extractor = VideoExtractor()

    func testCanExtractFromVideoData() {
        XCTAssertTrue(extractor.canExtract(from: .videoData(Data(), filename: "test.mp4")))
    }

    func testCanExtractFromVideoFileURL() {
        let url = URL(fileURLWithPath: "/tmp/clip.mp4")
        XCTAssertTrue(extractor.canExtract(from: .fileURL(url)))
    }

    func testCannotExtractFromImageFileURL() {
        let url = URL(fileURLWithPath: "/tmp/photo.png")
        XCTAssertFalse(extractor.canExtract(from: .fileURL(url)))
    }

    func testCannotExtractFromText() {
        XCTAssertFalse(extractor.canExtract(from: .text("hello")))
    }

    func testExtractFromVideoData() async throws {
        // MP4 with ftyp box at offset 4
        var data = Data(repeating: 0x00, count: 12)
        data[4] = 0x66 // f
        data[5] = 0x74 // t
        data[6] = 0x79 // y
        data[7] = 0x70 // p

        let content = try await extractor.extract(from: .videoData(data, filename: "test.mp4"))

        XCTAssertEqual(content.contentType, .video)
        XCTAssertEqual(content.title, "test.mp4")
        XCTAssertEqual(content.metadata["videoFormat"], "MP4")
        XCTAssertEqual(content.metadata["filename"], "test.mp4")
    }

    func testDetectMP4Format() {
        var data = Data(repeating: 0x00, count: 12)
        data[4] = 0x66; data[5] = 0x74; data[6] = 0x79; data[7] = 0x70
        XCTAssertEqual(extractor.detectVideoFormat(data), "MP4")
    }

    func testDetectFLVFormat() {
        var data = Data(repeating: 0x00, count: 12)
        data[0] = 0x46; data[1] = 0x4C; data[2] = 0x56
        XCTAssertEqual(extractor.detectVideoFormat(data), "FLV")
    }

    func testDetectWebMFormat() {
        var data = Data(repeating: 0x00, count: 12)
        data[0] = 0x1A; data[1] = 0x45; data[2] = 0xDF; data[3] = 0xA3
        XCTAssertEqual(extractor.detectVideoFormat(data), "WEBM")
    }

    func testDetectUnknownFormat() {
        let data = Data(repeating: 0x00, count: 12)
        XCTAssertNil(extractor.detectVideoFormat(data))
    }

    func testDetectTooShortData() {
        let data = Data([0xFF])
        XCTAssertNil(extractor.detectVideoFormat(data))
    }

    func testUnsupportedSourceThrows() async {
        do {
            _ = try await extractor.extract(from: .text("not a video"))
            XCTFail("Expected error for unsupported source")
        } catch {
            XCTAssertTrue(error is ExtractionError)
        }
    }
}
