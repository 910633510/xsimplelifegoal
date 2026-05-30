import XCTest
@testable import xsimpleLifeGoal

final class ModelManagerTests: XCTestCase {
    func testDefaultModelManifestUsesQwen17BGGUF() {
        let model = ModelManager.defaultModel

        XCTAssertEqual(model.id, "qwen3-1.7b-gguf")
        XCTAssertEqual(model.displayName, "Qwen3 1.7B GGUF")
        XCTAssertEqual(model.remoteURL.absoluteString, "https://huggingface.co/Qwen/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q8_0.gguf")
        XCTAssertEqual(model.localFilename, "Qwen3-1.7B-Q8_0.gguf")
        XCTAssertEqual(model.approximateBytes, 1_830_000_000)
        XCTAssertEqual(model.status, .notDownloaded)
    }

    func testSmallFallbackManifestUsesQwen06BGGUF() {
        let model = ModelManager.smallFallbackModel

        XCTAssertEqual(model.id, "qwen3-0.6b-gguf")
        XCTAssertEqual(model.displayName, "Qwen3 0.6B GGUF")
        XCTAssertEqual(model.remoteURL.absoluteString, "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf")
        XCTAssertEqual(model.localFilename, "Qwen3-0.6B-Q8_0.gguf")
        XCTAssertEqual(model.approximateBytes, 639_000_000)
        XCTAssertEqual(model.status, .notDownloaded)
    }

    func testReportsMissingLocalModelAsNotReady() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory)

        XCTAssertFalse(manager.isModelReady(ModelManager.defaultModel))
    }

    func testLocalURLUsesModelsDirectoryAndModelFilename() {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory)

        let expectedURL = tempDirectory
            .appending(path: "Models", directoryHint: .isDirectory)
            .appending(path: ModelManager.defaultModel.localFilename)

        XCTAssertEqual(manager.localURL(for: ModelManager.defaultModel), expectedURL)
    }

    func testEnsureModelDirectoryExistsCreatesModelsDirectory() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory)

        try manager.ensureModelDirectoryExists()

        let modelsDirectory = tempDirectory.appending(path: "Models", directoryHint: .isDirectory)
        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: modelsDirectory.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }
}
