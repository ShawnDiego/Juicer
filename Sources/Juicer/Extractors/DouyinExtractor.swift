import Foundation

/// Extracts content from Douyin (抖音) links.
public struct DouyinExtractor: ContentExtractor {
    public let supportedType: ContentType = .douyinLink

    private let networkClient: NetworkClient

    public init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    public func canExtract(from source: ContentSource) -> Bool {
        guard case .url(let urlString) = source else { return false }
        return LinkDetector().isDouyinURL(urlString)
    }

    public func extract(from source: ContentSource) async throws -> ExtractedContent {
        guard case .url(let urlString) = source else {
            throw ExtractionError.unsupportedSource
        }

        guard URL(string: urlString) != nil else {
            throw ExtractionError.invalidURL(urlString)
        }

        let html = try await networkClient.fetchHTML(from: urlString)
        return parseDouyinHTML(html, source: source, url: urlString)
    }

    // MARK: - Parsing

    func parseDouyinHTML(_ html: String, source: ContentSource, url: String) -> ExtractedContent {
        let title = extractMetaContent(from: html, property: "og:title")
            ?? extractTag(from: html, tag: "title")
        let description = extractMetaContent(from: html, property: "og:description")
            ?? extractMetaContent(from: html, name: "description")
        let author = extractMetaContent(from: html, property: "og:author")
            ?? extractMetaContent(from: html, name: "author")
        let imageURL = extractMetaContent(from: html, property: "og:image")
        let videoURL = extractMetaContent(from: html, property: "og:video")
            ?? extractMetaContent(from: html, property: "og:video:url")

        return ExtractedContent(
            contentType: .douyinLink,
            source: source,
            title: title,
            textContent: description,
            imageURLs: imageURL.map { [$0] } ?? [],
            videoURLs: videoURL.map { [$0] } ?? [],
            author: author,
            metadata: ["originalURL": url, "platform": "douyin"]
        )
    }
}

// MARK: - HTML Parsing Helpers (shared)

func extractMetaContent(from html: String, property: String) -> String? {
    // Match <meta property="..." content="...">
    let pattern = "<meta[^>]+property=[\"']\(NSRegularExpression.escapedPattern(for: property))[\"'][^>]+content=[\"']([^\"']*)[\"']"
    if let match = html.range(of: pattern, options: .regularExpression) {
        let substring = html[match]
        if let contentRange = substring.range(of: "content=[\"']", options: .regularExpression),
           let endQuote = substring[contentRange.upperBound...].firstIndex(where: { $0 == "\"" || $0 == "'" }) {
            return String(substring[contentRange.upperBound..<endQuote])
        }
    }

    // Try reversed attribute order: content before property
    let reversedPattern = "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+property=[\"']\(NSRegularExpression.escapedPattern(for: property))[\"']"
    if let match = html.range(of: reversedPattern, options: .regularExpression) {
        let substring = html[match]
        if let contentRange = substring.range(of: "content=[\"']", options: .regularExpression),
           let endQuote = substring[contentRange.upperBound...].firstIndex(where: { $0 == "\"" || $0 == "'" }) {
            return String(substring[contentRange.upperBound..<endQuote])
        }
    }

    return nil
}

func extractMetaContent(from html: String, name: String) -> String? {
    let pattern = "<meta[^>]+name=[\"']\(NSRegularExpression.escapedPattern(for: name))[\"'][^>]+content=[\"']([^\"']*)[\"']"
    if let match = html.range(of: pattern, options: .regularExpression) {
        let substring = html[match]
        if let contentRange = substring.range(of: "content=[\"']", options: .regularExpression),
           let endQuote = substring[contentRange.upperBound...].firstIndex(where: { $0 == "\"" || $0 == "'" }) {
            return String(substring[contentRange.upperBound..<endQuote])
        }
    }

    // Try reversed attribute order
    let reversedPattern = "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+name=[\"']\(NSRegularExpression.escapedPattern(for: name))[\"']"
    if let match = html.range(of: reversedPattern, options: .regularExpression) {
        let substring = html[match]
        if let contentRange = substring.range(of: "content=[\"']", options: .regularExpression),
           let endQuote = substring[contentRange.upperBound...].firstIndex(where: { $0 == "\"" || $0 == "'" }) {
            return String(substring[contentRange.upperBound..<endQuote])
        }
    }

    return nil
}

func extractTag(from html: String, tag: String) -> String? {
    let pattern = "<\(tag)[^>]*>([^<]*)</\(tag)>"
    guard let match = html.range(of: pattern, options: .regularExpression) else {
        return nil
    }
    let substring = html[match]
    if let openEnd = substring.range(of: ">"),
       let closeStart = substring.range(of: "</", options: .backwards) {
        let content = String(substring[openEnd.upperBound..<closeStart.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? nil : content
    }
    return nil
}
