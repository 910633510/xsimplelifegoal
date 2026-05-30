import XCTest
@testable import xsimpleLifeGoal

final class ModelManagerTests: XCTestCase {
    func testDefaultModelManifestUsesQwen17BGGUF() {
        let model = ModelManager.defaultModel

        XCTAssertEqual(model.id, "qwen3-1.7b-gguf")
        XCTAssertEqual(model.displayName, "Qwen3 1.7B GGUF")
        XCTAssertTrue(model.remoteURL.absoluteString.contains("Qwen3-1.7B-GGUF"))
    }

    func testSmallFallbackManifestUsesQwen06BGGUF() {
        let model = ModelManager.smallFallbackModel

        XCTAssertEqual(model.id, "qwen3-0.6b-gguf")
        XCTAssertTrue(model.remoteURL.absoluteString.contains("Qwen3-0.6B-GGUF"))
    }

    func testReportsMissingLocalModelAsNotReady() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory)

        XCTAssertFalse(manager.isModelReady(ModelManager.defaultModel))
    }
}
