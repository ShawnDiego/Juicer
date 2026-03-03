import Foundation

/// A default content analyzer that performs basic text analysis locally.
public struct DefaultContentAnalyzer: ContentAnalyzer {

    public init() {}

    public func analyze(_ content: ExtractedContent) async throws -> AnalysisResult {
        let text = content.textContent ?? content.title ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              || !content.imageURLs.isEmpty
              || !content.videoURLs.isEmpty else {
            throw AnalysisError.emptyContent
        }

        let summary = generateSummary(from: content)
        let keywords = extractKeywords(from: text)
        let language = detectLanguage(text)
        let labels = generateLabels(for: content)
        let wordCount = countWords(in: text)
        let hasMedia = !content.imageURLs.isEmpty || !content.videoURLs.isEmpty

        var metadata: [String: String] = [:]
        if hasMedia {
            metadata["imageCount"] = "\(content.imageURLs.count)"
            metadata["videoCount"] = "\(content.videoURLs.count)"
        }

        return AnalysisResult(
            extractedContent: content,
            summary: summary,
            keywords: keywords,
            language: language,
            labels: labels,
            wordCount: wordCount,
            hasMedia: hasMedia,
            metadata: metadata
        )
    }

    // MARK: - Private Analysis Methods

    func generateSummary(from content: ExtractedContent) -> String {
        var parts: [String] = []

        if let title = content.title {
            parts.append(title)
        }

        if let text = content.textContent {
            let truncated = text.count > 200 ? String(text.prefix(197)) + "..." : text
            if truncated != content.title {
                parts.append(truncated)
            }
        }

        if !content.imageURLs.isEmpty {
            parts.append("Contains \(content.imageURLs.count) image(s).")
        }

        if !content.videoURLs.isEmpty {
            parts.append("Contains \(content.videoURLs.count) video(s).")
        }

        return parts.isEmpty ? "No content available for summary." : parts.joined(separator: " ")
    }

    func extractKeywords(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        // Simple keyword extraction: split, filter short/stop words, count frequency
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !Self.stopWords.contains($0) }

        var frequency: [String: Int] = [:]
        for word in words {
            frequency[word, default: 0] += 1
        }

        // Return top keywords sorted by frequency
        return frequency
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }

    func detectLanguage(_ text: String) -> String? {
        guard !text.isEmpty else { return nil }

        // Heuristic: check for CJK characters
        let cjkRange = text.unicodeScalars.filter {
            (0x4E00...0x9FFF).contains($0.value) || // CJK Unified
            (0x3400...0x4DBF).contains($0.value)     // CJK Extension A
        }

        if cjkRange.count > text.count / 4 {
            return "zh" // Chinese
        }

        // Check for Japanese-specific characters
        let hiragana = text.unicodeScalars.filter { (0x3040...0x309F).contains($0.value) }
        let katakana = text.unicodeScalars.filter { (0x30A0...0x30FF).contains($0.value) }
        if !hiragana.isEmpty || !katakana.isEmpty {
            return "ja" // Japanese
        }

        // Default to English for Latin scripts
        let latin = text.unicodeScalars.filter { (0x0041...0x007A).contains($0.value) }
        if latin.count > text.count / 3 {
            return "en" // English
        }

        return nil
    }

    func generateLabels(for content: ExtractedContent) -> [String] {
        var labels: [String] = []

        labels.append(content.contentType.rawValue)

        if !content.imageURLs.isEmpty {
            labels.append("has-images")
        }
        if !content.videoURLs.isEmpty {
            labels.append("has-video")
        }
        if let author = content.author, !author.isEmpty {
            labels.append("has-author")
        }

        return labels
    }

    func countWords(in text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    // Common English stop words for keyword filtering
    static let stopWords: Set<String> = [
        "the", "is", "at", "which", "on", "a", "an", "and", "or", "but",
        "in", "with", "to", "for", "of", "not", "no", "can", "had", "have",
        "was", "were", "has", "this", "that", "from", "are", "been", "being",
        "will", "would", "could", "should", "may", "might", "shall", "did",
        "do", "does", "its", "it", "they", "them", "their", "there", "then",
        "than", "these", "those", "what", "when", "where", "who", "how",
        "all", "each", "every", "both", "few", "more", "most", "other",
        "some", "such", "only", "own", "same", "so", "very", "just"
    ]
}
