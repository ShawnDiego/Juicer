import XCTest
@testable import Juicer

final class JuicerConfigurationTests: XCTestCase {

    func testDefaultConfiguration() {
        let config = JuicerConfiguration.default
        XCTAssertEqual(config.maxConcurrency, 4)
        XCTAssertEqual(config.networkTimeout, 30)
        XCTAssertTrue(config.cachingEnabled)
        XCTAssertEqual(config.maxCacheSize, 100)
        XCTAssertEqual(config.maxTextLength, 0)
        XCTAssertEqual(config.maxKeywords, 10)
        XCTAssertFalse(config.userAgent.isEmpty)
    }

    func testCustomConfiguration() {
        let config = JuicerConfiguration(
            maxConcurrency: 8,
            networkTimeout: 60,
            cachingEnabled: false,
            maxCacheSize: 50,
            maxTextLength: 10000,
            maxKeywords: 20
        )
        XCTAssertEqual(config.maxConcurrency, 8)
        XCTAssertEqual(config.networkTimeout, 60)
        XCTAssertFalse(config.cachingEnabled)
        XCTAssertEqual(config.maxCacheSize, 50)
        XCTAssertEqual(config.maxTextLength, 10000)
        XCTAssertEqual(config.maxKeywords, 20)
    }

    func testMinimumClamping() {
        let config = JuicerConfiguration(
            maxConcurrency: 0,
            networkTimeout: -5,
            maxCacheSize: -1,
            maxTextLength: -100,
            maxKeywords: 0
        )
        XCTAssertEqual(config.maxConcurrency, 1) // Clamped to 1
        XCTAssertEqual(config.networkTimeout, 1) // Clamped to 1
        XCTAssertEqual(config.maxCacheSize, 1)   // Clamped to 1
        XCTAssertEqual(config.maxTextLength, 0)  // Clamped to 0
        XCTAssertEqual(config.maxKeywords, 1)    // Clamped to 1
    }

    func testJuicerUsesConfiguration() {
        let config = JuicerConfiguration(cachingEnabled: false)
        let juicer = Juicer(configuration: config)
        XCTAssertFalse(juicer.configuration.cachingEnabled)
    }

    // MARK: - maxTextLength Enforcement

    func testMaxTextLengthEnforced() async {
        let config = JuicerConfiguration(maxTextLength: 10)
        let juicer = Juicer(configuration: config)

        do {
            _ = try await juicer.process(input: "This text is definitely longer than ten characters")
            XCTFail("Expected textTooLong error")
        } catch {
            XCTAssertEqual(error as? ExtractionError, .textTooLong(10))
        }
    }

    func testMaxTextLengthAllowsShortText() async throws {
        let config = JuicerConfiguration(maxTextLength: 100)
        let juicer = Juicer(configuration: config)

        let result = try await juicer.process(input: "Short text")
        XCTAssertEqual(result.extractedContent.contentType, .text)
    }

    func testMaxTextLengthZeroMeansUnlimited() async throws {
        let config = JuicerConfiguration(maxTextLength: 0)
        let juicer = Juicer(configuration: config)

        let longText = String(repeating: "a", count: 100000)
        let result = try await juicer.process(input: longText)
        XCTAssertEqual(result.extractedContent.contentType, .text)
    }

    func testMaxTextLengthEnforcedOnExtract() async {
        let config = JuicerConfiguration(maxTextLength: 5)
        let juicer = Juicer(configuration: config)

        do {
            _ = try await juicer.extract(input: "This is too long")
            XCTFail("Expected textTooLong error")
        } catch {
            XCTAssertEqual(error as? ExtractionError, .textTooLong(5))
        }
    }

    // MARK: - maxKeywords Enforcement

    func testMaxKeywordsRespected() async throws {
        let config = JuicerConfiguration(maxKeywords: 3)
        let juicer = Juicer(configuration: config)

        let text = "swift programming language swift development swift tools golang python rust java"
        let result = try await juicer.process(input: text)
        XCTAssertLessThanOrEqual(result.keywords.count, 3)
    }
}
