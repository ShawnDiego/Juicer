import Foundation

/// A protocol that defines how content is extracted from a source.
public protocol ContentExtractor: Sendable {
    /// The content type this extractor handles.
    var supportedType: ContentType { get }

    /// Returns whether this extractor can handle the given source.
    func canExtract(from source: ContentSource) -> Bool

    /// Extracts content from the given source.
    func extract(from source: ContentSource) async throws -> ExtractedContent
}

/// Errors that can occur during content extraction.
public enum ExtractionError: Error, LocalizedError {
    case unsupportedSource
    case networkError(Error)
    case parsingError(String)
    case invalidURL(String)
    case noContentFound

    public var errorDescription: String? {
        switch self {
        case .unsupportedSource:
            return "The content source is not supported by this extractor."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Failed to parse content: \(message)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .noContentFound:
            return "No extractable content was found."
        }
    }
}
