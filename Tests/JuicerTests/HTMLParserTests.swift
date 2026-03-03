import XCTest
@testable import Juicer

final class HTMLParserTests: XCTestCase {

    let parser = HTMLParser()

    // MARK: - Meta Content Extraction

    func testExtractMetaProperty() {
        let html = """
        <html><head>
        <meta property="og:title" content="Test Title">
        </head></html>
        """
        XCTAssertEqual(parser.metaContent(from: html, property: "og:title"), "Test Title")
    }

    func testExtractMetaName() {
        let html = """
        <html><head>
        <meta name="description" content="Test Description">
        </head></html>
        """
        XCTAssertEqual(parser.metaContent(from: html, name: "description"), "Test Description")
    }

    func testExtractMissingMeta() {
        let html = "<html><head></head></html>"
        XCTAssertNil(parser.metaContent(from: html, property: "og:title"))
        XCTAssertNil(parser.metaContent(from: html, name: "description"))
    }

    func testExtractTagContent() {
        let html = "<html><head><title>Page Title</title></head></html>"
        XCTAssertEqual(parser.tagContent(from: html, tag: "title"), "Page Title")
    }

    func testExtractMissingTag() {
        let html = "<html><head></head></html>"
        XCTAssertNil(parser.tagContent(from: html, tag: "title"))
    }

    func testExtractAllMetaContents() {
        let html = """
        <html><head>
        <meta property="og:image" content="https://img1.jpg">
        <meta property="og:image" content="https://img2.jpg">
        <meta property="og:image" content="https://img3.jpg">
        </head></html>
        """
        let images = parser.allMetaContents(from: html, property: "og:image")
        XCTAssertEqual(images.count, 3)
        XCTAssertEqual(images[0], "https://img1.jpg")
        XCTAssertEqual(images[2], "https://img3.jpg")
    }

    // MARK: - HTML Entity Decoding

    func testDecodeNamedEntities() {
        XCTAssertEqual(parser.decodeHTMLEntities("&amp;"), "&")
        XCTAssertEqual(parser.decodeHTMLEntities("&lt;"), "<")
        XCTAssertEqual(parser.decodeHTMLEntities("&gt;"), ">")
        XCTAssertEqual(parser.decodeHTMLEntities("&quot;"), "\"")
        XCTAssertEqual(parser.decodeHTMLEntities("&apos;"), "'")
        XCTAssertEqual(parser.decodeHTMLEntities("&#39;"), "'")
    }

    func testDecodeDecimalEntities() {
        XCTAssertEqual(parser.decodeHTMLEntities("&#65;"), "A")
        XCTAssertEqual(parser.decodeHTMLEntities("&#97;"), "a")
        XCTAssertEqual(parser.decodeHTMLEntities("&#20320;&#22909;"), "你好")
    }

    func testDecodeHexEntities() {
        XCTAssertEqual(parser.decodeHTMLEntities("&#x41;"), "A")
        XCTAssertEqual(parser.decodeHTMLEntities("&#x61;"), "a")
    }

    func testDecodeMixedEntities() {
        let input = "Hello &amp; &#x57;orld &lt;3"
        XCTAssertEqual(parser.decodeHTMLEntities(input), "Hello & World <3")
    }

    func testDecodeNoEntities() {
        XCTAssertEqual(parser.decodeHTMLEntities("plain text"), "plain text")
    }

    func testMetaContentWithHTMLEntities() {
        let html = """
        <html><head>
        <meta property="og:title" content="Tom &amp; Jerry">
        </head></html>
        """
        XCTAssertEqual(parser.metaContent(from: html, property: "og:title"), "Tom & Jerry")
    }
}
