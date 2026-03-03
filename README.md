# Juicer

A Swift package for extracting and analyzing content from **Douyin (抖音)** links, **Xiaohongshu (小红书)** links, plain text, images, and videos. Designed for **iOS** and **macOS**.

## Features

- 🔗 **Link Detection** — Automatically detects Douyin and Xiaohongshu URLs from shared text
- 📝 **Text Extraction** — Analyzes plain text, detects embedded URLs, generates summaries
- 🖼️ **Image Processing** — Reads image metadata and detects formats (JPEG, PNG, GIF, BMP, WebP)
- 🎬 **Video Processing** — Reads video metadata and detects formats (MP4, AVI, FLV, WebM)
- 🌐 **Web Content Extraction** — Fetches and parses HTML (Open Graph metadata) from Douyin and Xiaohongshu pages
- 🧠 **Content Analysis** — Keyword extraction, language detection, word count, summary generation
- 📱 **Cross-platform** — Runs on iOS 16+ and macOS 13+

## Architecture

```
Sources/Juicer/
├── Models/
│   ├── ContentType.swift        # Content type enum (douyinLink, xiaohongshuLink, text, image, video)
│   ├── ContentSource.swift      # Input source enum (url, text, imageData, videoData, fileURL)
│   ├── ExtractedContent.swift   # Extracted content model
│   └── AnalysisResult.swift     # Analysis result model
├── LinkDetector/
│   └── LinkDetector.swift       # URL detection and classification
├── Extractors/
│   ├── ContentExtractor.swift   # Extractor protocol
│   ├── DouyinExtractor.swift    # Douyin HTML parser
│   ├── XiaohongshuExtractor.swift # Xiaohongshu HTML parser
│   ├── TextExtractor.swift      # Plain text processor
│   ├── ImageExtractor.swift     # Image metadata extractor
│   └── VideoExtractor.swift     # Video metadata extractor
├── Analyzers/
│   ├── ContentAnalyzer.swift    # Analyzer protocol
│   └── DefaultContentAnalyzer.swift # Local text analysis
├── Networking/
│   └── NetworkClient.swift      # HTTP client
└── Juicer.swift                 # Main entry point
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

### Extract Without Analysis

```swift
let content = try await juicer.extract(input: "https://v.douyin.com/abc123")
print(content.title)
print(content.imageURLs)
print(content.videoURLs)
```

### Custom Analyzer

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