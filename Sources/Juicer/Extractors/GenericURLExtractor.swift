import Foundation

/// Extracts content from generic web URLs using Open Graph metadata.
///
/// This extractor handles any HTTP/HTTPS URL that is not handled by the
/// platform-specific extractors (Douyin, Xiaohongshu). It fetches the page
/// HTML and parses standard Open Graph and HTML meta tags.
public struct GenericURLExtractor: ContentExtractor {
    public let supportedType: ContentType = .text

    private let networkClient: NetworkClient
    private let htmlParser: HTMLParser
    private let linkDetector: LinkDetector

    public init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
        self.htmlParser = HTMLParser()
        self.linkDetector = LinkDetector()
    }

    public func canExtract(from source: ContentSource) -> Bool {
        guard case .url(let urlString) = source else { return false }
        // Only handle URLs that are NOT Douyin or Xiaohongshu
        guard URL(string: urlString) != nil else { return false }
        return !linkDetector.isDouyinURL(urlString) && !linkDetector.isXiaohongshuURL(urlString)
    }

    public func extract(from source: ContentSource) async throws -> ExtractedContent {
        guard case .url(let urlString) = source else {
            throw ExtractionError.unsupportedSource
        }

        guard URL(string: urlString) != nil else {
            throw ExtractionError.invalidURL(urlString)
        }

        let html = try await networkClient.fetchHTML(from: urlString)
        return parseHTML(html, source: source, url: urlString)
    }

    // MARK: - Parsing

    func parseHTML(_ html: String, source: ContentSource, url: String) -> ExtractedContent {
        let title = htmlParser.metaContent(from: html, property: "og:title")
            ?? htmlParser.tagContent(from: html, tag: "title")
        let description = htmlParser.metaContent(from: html, property: "og:description")
            ?? htmlParser.metaContent(from: html, name: "description")
        let author = htmlParser.metaContent(from: html, property: "og:author")
            ?? htmlParser.metaContent(from: html, name: "author")
        let siteName = htmlParser.metaContent(from: html, property: "og:site_name")
        let imageURL = htmlParser.metaContent(from: html, property: "og:image")
        let videoURL = htmlParser.metaContent(from: html, property: "og:video")
            ?? htmlParser.metaContent(from: html, property: "og:video:url")
        let contentType = htmlParser.metaContent(from: html, property: "og:type")

        var metadata: [String: String] = ["originalURL": url]
        if let siteName = siteName {
            metadata["siteName"] = siteName
        }
        if let contentType = contentType {
            metadata["ogType"] = contentType
        }

        return ExtractedContent(
            contentType: .text,
            source: source,
            title: title,
            textContent: description,
            imageURLs: imageURL.map { [$0] } ?? [],
            videoURLs: videoURL.map { [$0] } ?? [],
            author: author,
            metadata: metadata
        )
    }
}
