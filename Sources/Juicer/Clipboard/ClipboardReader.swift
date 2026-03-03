import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A cross-platform utility for reading content from the system clipboard.
///
/// On iOS, it uses `UIPasteboard`. On macOS, it uses `NSPasteboard`.
/// On other platforms, it provides a stub that returns `nil`.
///
/// ## Usage
/// ```swift
/// let reader = ClipboardReader()
/// if let source = reader.read() {
///     let result = try await juicer.process(source: source)
/// }
/// ```
public struct ClipboardReader: Sendable {

    public init() {}

    /// Reads the current clipboard content and returns a `ContentSource`, or `nil` if empty.
    ///
    /// The method checks for content in the following order:
    /// 1. Image data (PNG, JPEG)
    /// 2. URL
    /// 3. Plain text
    public func read() -> ContentSource? {
        #if canImport(UIKit)
        return readFromUIKit()
        #elseif canImport(AppKit)
        return readFromAppKit()
        #else
        return nil
        #endif
    }

    /// Returns whether the clipboard currently has readable content.
    public func hasContent() -> Bool {
        return read() != nil
    }

    // MARK: - Platform Implementations

    #if canImport(UIKit)
    private func readFromUIKit() -> ContentSource? {
        let pasteboard = UIPasteboard.general

        // Check for image data first
        if let imageData = pasteboard.data(forPasteboardType: "public.png") {
            return .imageData(imageData, filename: "clipboard.png")
        }
        if let imageData = pasteboard.data(forPasteboardType: "public.jpeg") {
            return .imageData(imageData, filename: "clipboard.jpg")
        }

        // Check for URL
        if let url = pasteboard.url {
            return .url(url.absoluteString)
        }

        // Check for text
        if let text = pasteboard.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .text(text)
        }

        return nil
    }
    #endif

    #if canImport(AppKit)
    private func readFromAppKit() -> ContentSource? {
        let pasteboard = NSPasteboard.general

        // Check for image data first
        if let imageData = pasteboard.data(forType: .png) {
            return .imageData(imageData, filename: "clipboard.png")
        }
        if let imageData = pasteboard.data(forType: .tiff) {
            return .imageData(imageData, filename: "clipboard.tiff")
        }

        // Check for URL
        if let urlString = pasteboard.string(forType: .URL),
           let _ = URL(string: urlString) {
            return .url(urlString)
        }

        // Check for text
        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .text(text)
        }

        return nil
    }
    #endif
}
