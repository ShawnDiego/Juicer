# Juicer

A Swift package for extracting and analyzing content from **Douyin (抖音)** links, **Xiaohongshu (小红书)** links, **generic web URLs**, plain text, images, and videos. Designed for **iOS** and **macOS**, with processing available locally or via custom cloud backends.

## Features

- 🔗 **Link Detection** — Automatically detects Douyin and Xiaohongshu URLs from shared text
- 🌐 **Generic URL Extraction** — Fetches and parses Open Graph metadata from any web URL
- 📝 **Text Extraction** — Analyzes plain text, detects embedded URLs, generates summaries
- 🖼️ **Image Processing** — Reads image metadata and detects formats (JPEG, PNG, GIF, BMP, WebP)
- 🎬 **Video Processing** — Reads video metadata and detects formats (MP4, AVI, FLV, WebM)
- 🧠 **Content Analysis** — Keyword extraction, language detection, hashtag/mention parsing, word count, summary generation
- 📋 **Clipboard Integration** — Read content directly from the system clipboard (iOS/macOS)
- ⚡ **Batch Processing** — Process multiple inputs concurrently with configurable parallelism
- 💾 **Caching** — In-memory LRU cache to avoid redundant extractions
- 📦 **Codable Models** — All models are `Codable` for easy serialization and persistence
- ⚙️ **Configurable** — Customize timeouts, cache size, concurrency, and more
- 📱 **Cross-platform** — Runs on iOS 16+ and macOS 13+

## Architecture

```
Sources/Juicer/
├── Models/
│   ├── ContentType.swift          # Content type enum
│   ├── ContentSource.swift        # Input source enum (Codable)
│   ├── ExtractedContent.swift     # Extracted content model (Codable)
│   ├── AnalysisResult.swift       # Analysis result model (Codable)
│   └── JuicerConfiguration.swift  # Configuration options
├── LinkDetector/
│   └── LinkDetector.swift         # URL detection and classification
├── Extractors/
│   ├── ContentExtractor.swift     # Extractor protocol
│   ├── DouyinExtractor.swift      # Douyin HTML parser
│   ├── XiaohongshuExtractor.swift # Xiaohongshu HTML parser
│   ├── GenericURLExtractor.swift  # Generic Open Graph URL extractor
│   ├── TextExtractor.swift        # Plain text processor
│   ├── ImageExtractor.swift       # Image metadata extractor
│   └── VideoExtractor.swift       # Video metadata extractor
├── Analyzers/
│   ├── ContentAnalyzer.swift      # Analyzer protocol
│   └── DefaultContentAnalyzer.swift # Local text/hashtag/mention analysis
├── Parsing/
│   └── HTMLParser.swift           # HTML parsing + entity decoding
├── Networking/
│   └── NetworkClient.swift        # HTTP client
├── Cache/
│   └── ContentCache.swift         # In-memory LRU cache
├── Clipboard/
│   └── ClipboardReader.swift      # iOS/macOS clipboard reader
└── Juicer.swift                   # Main entry point
```

## Usage

### Quick Start

```swift
import Juicer

let juicer = Juicer()

// Process a Douyin link shared from the app
let result = try await juicer.process(input: "来看看这个视频 https://v.douyin.com/abc123 太好看了！")
print(result.summary)
print(result.extractedContent.title)

// Process a Xiaohongshu link
let result = try await juicer.process(input: "https://www.xiaohongshu.com/explore/abc123")
print(result.extractedContent.author)

// Process any web URL (Open Graph metadata)
let result = try await juicer.process(input: "https://medium.com/some-article")
print(result.extractedContent.title)

// Process plain text
let result = try await juicer.process(input: "这是一段需要分析的文字内容")
print(result.keywords)
print(result.language) // "zh"

// Process an image
let result = try await juicer.process(source: .imageData(imageData, filename: "photo.jpg"))
print(result.extractedContent.metadata["imageFormat"]) // "JPEG"

// Process a video
let result = try await juicer.process(source: .videoData(videoData, filename: "clip.mp4"))
print(result.extractedContent.metadata["videoFormat"]) // "MP4"
```

### Hashtag & Mention Extraction

```swift
let result = try await juicer.process(input: "#旅行日记 今天去了北京 @好友推荐")
print(result.metadata["hashtags"])  // "旅行日记"
print(result.metadata["mentions"])  // "好友推荐"
```

### Batch Processing

```swift
let inputs = ["Hello world", "https://v.douyin.com/abc", "Another text"]
let results = await juicer.processAll(inputs: inputs)
// results: [AnalysisResult?] — nil for failed inputs, preserves order
```

### Clipboard Integration (iOS/macOS)

```swift
// Read and process clipboard content directly
if let result = try? await juicer.processClipboard() {
    print(result.summary)
}

// Or check what's on the clipboard first
if let source = juicer.readClipboard() {
    let result = try await juicer.process(source: source)
}
```

### Extract Without Analysis

```swift
let content = try await juicer.extract(input: "https://v.douyin.com/abc123")
print(content.title)
print(content.imageURLs)
print(content.videoURLs)
```

### Serialization (Codable)

```swift
// Encode results to JSON
let data = try JSONEncoder().encode(result)

// Decode from JSON
let decoded = try JSONDecoder().decode(AnalysisResult.self, from: data)
```

### Configuration

```swift
let config = JuicerConfiguration(
    maxConcurrency: 8,       // Max parallel batch tasks
    networkTimeout: 60,      // HTTP timeout in seconds
    cachingEnabled: true,    // Enable in-memory caching
    maxCacheSize: 200,       // Max cache entries
    maxKeywords: 20          // Max keywords to extract
)

let juicer = Juicer(configuration: config)
```

### Custom Analyzer (Local or Cloud)

```swift
struct MyCloudAnalyzer: ContentAnalyzer {
    func analyze(_ content: ExtractedContent) async throws -> AnalysisResult {
        // Send content to your cloud AI service for analysis
        // ...
    }
}

let juicer = Juicer(analyzer: MyCloudAnalyzer())
```

## Integration

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ShawnDiego/Juicer.git", from: "0.1.0")
]
```

Or add via Xcode: **File → Add Package Dependencies** and enter the repository URL.

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.