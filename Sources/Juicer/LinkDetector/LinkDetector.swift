import Foundation

/// Detects and classifies URLs from Douyin, Xiaohongshu, and Weibo platforms.
public struct LinkDetector: Sendable {

    /// Known Douyin (抖音) host patterns.
    static let douyinHosts: Set<String> = [
        "www.douyin.com",
        "douyin.com",
        "v.douyin.com",
        "www.iesdouyin.com",
        "iesdouyin.com"
    ]

    /// Known Xiaohongshu (小红书) host patterns.
    static let xiaohongshuHosts: Set<String> = [
        "www.xiaohongshu.com",
        "xiaohongshu.com",
        "xhslink.com",
        "www.xhslink.com"
    ]

    /// Known Weibo (微博) host patterns.
    static let weiboHosts: Set<String> = [
        "weibo.com",
        "www.weibo.com",
        "m.weibo.cn",
        "weibo.cn",
        "www.weibo.cn"
    ]

    public init() {}

    /// Detects the content type from raw input text.
    /// The input may contain a URL embedded in surrounding text (e.g., shared from an app).
    ///
    /// - Parameter input: The raw string input to analyze.
    /// - Returns: A tuple of `(ContentType, String)` where the string is the cleaned URL,
    ///   or `.text` type with the original input if no link is detected.
    public func detect(_ input: String) -> (ContentType, String) {
        let urls = extractURLs(from: input)

        for url in urls {
            if let contentType = classifyURL(url) {
                return (contentType, url)
            }
        }

        return (.text, input)
    }

    /// Checks if a URL string matches a known Douyin host.
    public func isDouyinURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return false
        }
        return Self.douyinHosts.contains(host)
    }

    /// Checks if a URL string matches a known Xiaohongshu host.
    public func isXiaohongshuURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return false
        }
        return Self.xiaohongshuHosts.contains(host)
    }

    /// Checks if a URL string matches a known Weibo host.
    public func isWeiboURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return false
        }
        return Self.weiboHosts.contains(host)
    }

    /// Checks if a URL string is a valid HTTP/HTTPS URL.
    public func isGenericURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              url.host != nil else {
            return false
        }
        return true
    }

    // MARK: - Private

    /// Extracts all URL strings from the input text.
    func extractURLs(from text: String) -> [String] {
        // Use regex-based URL extraction for cross-platform compatibility
        let pattern = "https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=%]+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.compactMap { match in
            guard let matchRange = Range(match.range, in: text) else { return nil }
            return String(text[matchRange])
        }
    }

    /// Classifies a URL string into a ContentType.
    func classifyURL(_ urlString: String) -> ContentType? {
        if isDouyinURL(urlString) {
            return .douyinLink
        } else if isXiaohongshuURL(urlString) {
            return .xiaohongshuLink
        } else if isWeiboURL(urlString) {
            return .weiboLink
        }
        return nil
    }
}
