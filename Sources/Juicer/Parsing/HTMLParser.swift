import Foundation

/// Utility for parsing HTML content and extracting metadata.
public struct HTMLParser: Sendable {

    public init() {}

    /// Extracts the value of a `<meta>` tag's `content` attribute matching the given `property`.
    ///
    /// Handles both attribute orderings:
    /// - `<meta property="..." content="...">`
    /// - `<meta content="..." property="...">`
    public func metaContent(from html: String, property: String) -> String? {
        let result = extractMetaPropertyContent(from: html, property: property)
        return result.map { decodeHTMLEntities($0) }
    }

    /// Extracts the value of a `<meta>` tag's `content` attribute matching the given `name`.
    public func metaContent(from html: String, name: String) -> String? {
        let result = extractMetaNameContent(from: html, name: name)
        return result.map { decodeHTMLEntities($0) }
    }

    /// Extracts the inner text content of the first matching HTML tag.
    public func tagContent(from html: String, tag: String) -> String? {
        let result = extractTagContent(from: html, tag: tag)
        return result.map { decodeHTMLEntities($0) }
    }

    /// Extracts all values for a given meta `property` (e.g., multiple `og:image` tags).
    public func allMetaContents(from html: String, property: String) -> [String] {
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
                results.append(decodeHTMLEntities(String(html[range])))
            }
        }

        return results
    }

    /// Decodes common HTML entities in the given string.
    ///
    /// Handles named entities (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&apos;`, `&nbsp;`)
    /// and numeric character references (`&#123;`, `&#x1F4A;`).
    public func decodeHTMLEntities(_ string: String) -> String {
        var result = string

        // Named entities
        let namedEntities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&#39;", "'"),
            ("&nbsp;", "\u{00A0}")
        ]
        for (entity, replacement) in namedEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Decimal numeric references: &#123;
        if let regex = try? NSRegularExpression(pattern: "&#(\\d+);", options: []) {
            let nsRange = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: nsRange).reversed()
            for match in matches {
                if match.numberOfRanges > 1,
                   let numRange = Range(match.range(at: 1), in: result),
                   let fullRange = Range(match.range, in: result),
                   let codePoint = UInt32(result[numRange]),
                   let scalar = Unicode.Scalar(codePoint) {
                    result.replaceSubrange(fullRange, with: String(Character(scalar)))
                }
            }
        }

        // Hexadecimal numeric references: &#x1F4A;
        if let regex = try? NSRegularExpression(pattern: "&#x([0-9a-fA-F]+);", options: []) {
            let nsRange = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: nsRange).reversed()
            for match in matches {
                if match.numberOfRanges > 1,
                   let hexRange = Range(match.range(at: 1), in: result),
                   let fullRange = Range(match.range, in: result),
                   let codePoint = UInt32(result[hexRange], radix: 16),
                   let scalar = Unicode.Scalar(codePoint) {
                    result.replaceSubrange(fullRange, with: String(Character(scalar)))
                }
            }
        }

        return result
    }

    // MARK: - Private Parsing Helpers

    private func extractMetaPropertyContent(from html: String, property: String) -> String? {
        let escapedProp = NSRegularExpression.escapedPattern(for: property)

        // Match <meta property="..." content="...">
        let pattern = "<meta[^>]+property=[\"']\(escapedProp)[\"'][^>]+content=[\"']([^\"']*)[\"']"
        if let match = html.range(of: pattern, options: .regularExpression) {
            let substring = html[match]
            if let contentRange = substring.range(of: "content=[\"']", options: .regularExpression),
               let endQuote = substring[contentRange.upperBound...].firstIndex(where: { $0 == "\"" || $0 == "'" }) {
                return String(substring[contentRange.upperBound..<endQuote])
            }
        }

        // Try reversed attribute order: content before property
        let reversedPattern = "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+property=[\"']\(escapedProp)[\"']"
        if let match = html.range(of: reversedPattern, options: .regularExpression) {
            let substring = html[match]
            if let contentRange = substring.range(of: "content=[\"']", options: .regularExpression),
               let endQuote = substring[contentRange.upperBound...].firstIndex(where: { $0 == "\"" || $0 == "'" }) {
                return String(substring[contentRange.upperBound..<endQuote])
            }
        }

        return nil
    }

    private func extractMetaNameContent(from html: String, name: String) -> String? {
        let escapedName = NSRegularExpression.escapedPattern(for: name)

        let pattern = "<meta[^>]+name=[\"']\(escapedName)[\"'][^>]+content=[\"']([^\"']*)[\"']"
        if let match = html.range(of: pattern, options: .regularExpression) {
            let substring = html[match]
            if let contentRange = substring.range(of: "content=[\"']", options: .regularExpression),
               let endQuote = substring[contentRange.upperBound...].firstIndex(where: { $0 == "\"" || $0 == "'" }) {
                return String(substring[contentRange.upperBound..<endQuote])
            }
        }

        // Try reversed attribute order
        let reversedPattern = "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+name=[\"']\(escapedName)[\"']"
        if let match = html.range(of: reversedPattern, options: .regularExpression) {
            let substring = html[match]
            if let contentRange = substring.range(of: "content=[\"']", options: .regularExpression),
               let endQuote = substring[contentRange.upperBound...].firstIndex(where: { $0 == "\"" || $0 == "'" }) {
                return String(substring[contentRange.upperBound..<endQuote])
            }
        }

        return nil
    }

    private func extractTagContent(from html: String, tag: String) -> String? {
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
}
