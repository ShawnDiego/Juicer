import Foundation

/// Extracts content from Weibo (微博) links.
public struct WeiboExtractor: ContentExtractor {
    public let supportedType: ContentType = .weiboLink

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
        return linkDetector.isWeiboURL(urlString)
    }

    public func extract(from source: ContentSource) async throws -> ExtractedContent {
        guard case .url(let urlString) = source else {
            throw ExtractionError.unsupportedSource
        }

        guard URL(string: urlString) != nil else {
            throw ExtractionError.invalidURL(urlString)
        }

        let html = try await networkClient.fetchHTML(from: urlString)
        return parseWeiboHTML(html, source: source, url: urlString)
    }

    // MARK: - Parsing

    func parseWeiboHTML(_ html: String, source: ContentSource, url: String) -> ExtractedContent {
        let title = htmlParser.metaContent(from: html, property: "og:title")
            ?? htmlParser.tagContent(from: html, tag: "title")
        let description = htmlParser.metaContent(from: html, property: "og:description")
            ?? htmlParser.metaContent(from: html, name: "description")
        let author = htmlParser.metaContent(from: html, property: "og:author")
            ?? htmlParser.metaContent(from: html, name: "author")
        let imageURL = htmlParser.metaContent(from: html, property: "og:image")
        let videoURL = htmlParser.metaContent(from: html, property: "og:video")
            ?? htmlParser.metaContent(from: html, property: "og:video:url")

        var imageURLs: [String] = imageURL.map { [$0] } ?? []

        // Weibo posts often have multiple images
        let additionalImages = htmlParser.allMetaContents(from: html, property: "og:image")
        if additionalImages.count > imageURLs.count {
            imageURLs = additionalImages
        }

        return ExtractedContent(
            contentType: .weiboLink,
            source: source,
            title: title,
            textContent: description,
            imageURLs: imageURLs,
            videoURLs: videoURL.map { [$0] } ?? [],
            author: author,
            metadata: ["originalURL": url, "platform": "weibo"]
        )
    }
}
