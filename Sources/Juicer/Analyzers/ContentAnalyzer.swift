import Foundation

/// A protocol that defines how extracted content is analyzed.
public protocol ContentAnalyzer: Sendable {
    /// Analyzes extracted content and produces an analysis result.
    func analyze(_ content: ExtractedContent) async throws -> AnalysisResult
}

/// Errors that can occur during content analysis.
public enum AnalysisError: Error, LocalizedError, Equatable {
    case emptyContent
    case analysisUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "No content available for analysis."
        case .analysisUnavailable(let reason):
            return "Analysis unavailable: \(reason)"
        }
    }
}
