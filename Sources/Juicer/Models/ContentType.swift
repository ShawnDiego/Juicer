import Foundation

/// Represents the type of content being processed.
public enum ContentType: String, Sendable, Codable, CaseIterable {
    case douyinLink
    case xiaohongshuLink
    case text
    case image
    case video
}
