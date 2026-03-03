import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A simple HTTP client for fetching web content.
public struct NetworkClient: @unchecked Sendable {

    private let userAgent: String
    private let timeout: TimeInterval

    public init(
        userAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
        timeout: TimeInterval = 30
    ) {
        self.userAgent = userAgent
        self.timeout = timeout
    }

    /// Fetches the HTML content at the given URL string.
    public func fetchHTML(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw ExtractionError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ExtractionError.networkError(error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw ExtractionError.networkError("HTTP \(httpResponse.statusCode)")
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw ExtractionError.parsingError("Unable to decode response as UTF-8")
        }

        return html
    }
}
