import Foundation

/// Extracts content from plain text input.
public struct TextExtractor: ContentExtractor {
    public let supportedType: ContentType = .text

    public init() {}

    public func canExtract(from source: ContentSource) -> Bool {
        if case .text = source { return true }
        return false
    }

    public func extract(from source: ContentSource) async throws -> ExtractedContent {
        guard case .text(let text) = source else {
            throw ExtractionError.unsupportedSource
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExtractionError.noContentFound
        }

        let title = extractTitle(from: text)
        let urls = extractEmbeddedURLs(from: text)

        var metadata: [String: String] = [
            "characterCount": "\(text.count)",
            "lineCount": "\(text.components(separatedBy: .newlines).count)"
        ]

        if !urls.isEmpty {
            metadata["embeddedURLs"] = urls.joined(separator: ", ")
        }

        return ExtractedContent(
            contentType: .text,
            source: source,
            title: title,
            textContent: text,
            metadata: metadata
        )
    }

    // MARK: - Private

    /// Extracts a title from the text (first non-empty line, truncated).
    func extractTitle(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        guard let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            return nil
        }

        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 80 {
            return trimmed
        }
        return String(trimmed.prefix(77)) + "..."
    }

    /// Extracts embedded URLs from the text.
    func extractEmbeddedURLs(from text: String) -> [String] {
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
}
