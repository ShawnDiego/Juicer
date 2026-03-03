import Foundation

/// Extracts content from Douyin (抖音) links.
///
/// Supports:
/// - Short share links: `https://v.douyin.com/iRNxxx/`
/// - Video pages: `https://www.douyin.com/video/7234567890123456789`
/// - Note pages: `https://www.douyin.com/note/7234567890123456789`
/// - User pages: `https://www.douyin.com/user/MS4wLjABAAAAxxx`
/// - Shared text: `"7.29 PJu:/ 复制打开抖音，看看【xxx的作品】 https://v.douyin.com/iRNxxx/"`
///
/// The extractor follows HTTP redirects to resolve short URLs, extracts
/// the video/note ID, and parses Open Graph metadata from the page HTML.
public struct DouyinExtractor: ContentExtractor {
    public let supportedType: ContentType = .douyinLink

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
        return linkDetector.isDouyinURL(urlString)
    }

    public func extract(from source: ContentSource) async throws -> ExtractedContent {
        guard case .url(let urlString) = source else {
            throw ExtractionError.unsupportedSource
        }

        guard URL(string: urlString) != nil else {
            throw ExtractionError.invalidURL(urlString)
        }

        // Use redirect-following fetch to resolve short URLs (v.douyin.com/xxx → douyin.com/video/xxx)
        let (html, resolvedURL) = try await networkClient.fetchHTMLWithResolvedURL(from: urlString)
        return parseDouyinHTML(html, source: source, url: urlString, resolvedURL: resolvedURL)
    }

    // MARK: - Parsing

    func parseDouyinHTML(_ html: String, source: ContentSource, url: String, resolvedURL: String? = nil) -> ExtractedContent {
        let title = htmlParser.metaContent(from: html, property: "og:title")
            ?? htmlParser.tagContent(from: html, tag: "title")
        let description = htmlParser.metaContent(from: html, property: "og:description")
            ?? htmlParser.metaContent(from: html, name: "description")
        let author = htmlParser.metaContent(from: html, property: "og:author")
            ?? htmlParser.metaContent(from: html, name: "author")
        let imageURL = htmlParser.metaContent(from: html, property: "og:image")
        let videoURL = htmlParser.metaContent(from: html, property: "og:video")
            ?? htmlParser.metaContent(from: html, property: "og:video:url")

        var metadata: [String: String] = [
            "originalURL": url,
            "platform": "douyin"
        ]

        // Store the resolved URL (after redirect) if different from the original
        let finalURL = resolvedURL ?? url
        if finalURL != url {
            metadata["resolvedURL"] = finalURL
        }

        // Extract video ID or note ID from the resolved URL
        if let videoId = Self.extractVideoId(from: finalURL) {
            metadata["videoId"] = videoId
        } else if let noteId = Self.extractNoteId(from: finalURL) {
            metadata["noteId"] = noteId
        }

        // Detect content subtype (video vs. note/image post)
        if finalURL.contains("/note/") {
            metadata["contentSubtype"] = "note"
        } else if finalURL.contains("/video/") {
            metadata["contentSubtype"] = "video"
        }

        return ExtractedContent(
            contentType: .douyinLink,
            source: source,
            title: title,
            textContent: description,
            imageURLs: imageURL.map { [$0] } ?? [],
            videoURLs: videoURL.map { [$0] } ?? [],
            author: author,
            metadata: metadata
        )
    }

    // MARK: - URL Parsing

    private static let videoIdRegex = try! NSRegularExpression(pattern: "/video/(\\d+)", options: [])
    private static let noteIdRegex = try! NSRegularExpression(pattern: "/note/(\\d+)", options: [])

    /// Extracts the video ID from a Douyin URL.
    ///
    /// Matches patterns like:
    /// - `douyin.com/video/7234567890123456789`
    /// - `douyin.com/video/7234567890123456789?...`
    static func extractVideoId(from urlString: String) -> String? {
        let nsRange = NSRange(urlString.startIndex..., in: urlString)
        guard let match = videoIdRegex.firstMatch(in: urlString, options: [], range: nsRange),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: urlString) else {
            return nil
        }
        return String(urlString[range])
    }

    /// Extracts the note ID from a Douyin note URL.
    ///
    /// Matches patterns like:
    /// - `douyin.com/note/7234567890123456789`
    static func extractNoteId(from urlString: String) -> String? {
        let nsRange = NSRange(urlString.startIndex..., in: urlString)
        guard let match = noteIdRegex.firstMatch(in: urlString, options: [], range: nsRange),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: urlString) else {
            return nil
        }
        return String(urlString[range])
    }
}

// MARK: - HTML Parsing Helpers (shared, kept for backward compatibility)

func extractMetaContent(from html: String, property: String) -> String? {
    return HTMLParser().metaContent(from: html, property: property)
}

func extractMetaContent(from html: String, name: String) -> String? {
    return HTMLParser().metaContent(from: html, name: name)
}

func extractTag(from html: String, tag: String) -> String? {
    return HTMLParser().tagContent(from: html, tag: tag)
}
