import Foundation

/// Extracts content from Xiaohongshu (小红书) links.
public struct XiaohongshuExtractor: ContentExtractor {
    public let supportedType: ContentType = .xiaohongshuLink

    private let networkClient: NetworkClient

    public init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    public func canExtract(from source: ContentSource) -> Bool {
        guard case .url(let urlString) = source else { return false }
        return LinkDetector().isXiaohongshuURL(urlString)
    }

    public func extract(from source: ContentSource) async throws -> ExtractedContent {
        guard case .url(let urlString) = source else {
            throw ExtractionError.unsupportedSource
        }

        guard URL(string: urlString) != nil else {
            throw ExtractionError.invalidURL(urlString)
        }

        let html = try await networkClient.fetchHTML(from: urlString)
        return parseXiaohongshuHTML(html, source: source, url: urlString)
    }

    // MARK: - Parsing

    func parseXiaohongshuHTML(_ html: String, source: ContentSource, url: String) -> ExtractedContent {
        let title = extractMetaContent(from: html, property: "og:title")
            ?? extractTag(from: html, tag: "title")
        let description = extractMetaContent(from: html, property: "og:description")
            ?? extractMetaContent(from: html, name: "description")
        let author = extractMetaContent(from: html, property: "og:author")
            ?? extractMetaContent(from: html, name: "author")
        let imageURL = extractMetaContent(from: html, property: "og:image")
        let videoURL = extractMetaContent(from: html, property: "og:video")

        var imageURLs: [String] = imageURL.map { [$0] } ?? []

        // Extract additional images from og:image tags (Xiaohongshu posts often have multiple images)
        let additionalImages = extractAllMetaContents(from: html, property: "og:image")
        if additionalImages.count > imageURLs.count {
            imageURLs = additionalImages
        }

        return ExtractedContent(
            contentType: .xiaohongshuLink,
            source: source,
            title: title,
            textContent: description,
            imageURLs: imageURLs,
            videoURLs: videoURL.map { [$0] } ?? [],
            author: author,
            metadata: ["originalURL": url, "platform": "xiaohongshu"]
        )
    }

    /// Extracts all values for a given meta property (for multiple images, etc.).
    private func extractAllMetaContents(from html: String, property: String) -> [String] {
        var results: [String] = []
        let escapedProp = NSRegularExpression.escapedPattern(for: property)
        let pattern = "<meta[^>]+property=[\"']\(escapedProp)[\"'][^>]+content=[\"']([^\"']*)[\"']"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return results
        }

        let nsRange = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)

        for match in matches {
            if match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: html) {
                results.append(String(html[range]))
            }
        }

        return results
    }
}
