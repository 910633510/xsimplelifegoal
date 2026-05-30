import XCTest
@testable import xsimpleLifeGoal

final class ModelManagerTests: XCTestCase {
    @MainActor
    func testModelSetupViewModelStartsWithDefaultModel() {
        let manager = makeTemporaryModelManager()
        let viewModel = ModelSetupViewModel(modelManager: manager)

        XCTAssertEqual(viewModel.selectedModel.id, "qwen3-1.7b-gguf")
        XCTAssertFalse(viewModel.isReady)
        XCTAssertEqual(viewModel.statusText, "Model download required")
    }

    @MainActor
    func testModelSetupViewModelExposesSelectedModelLocalURL() {
        let manager = makeTemporaryModelManager()
        let viewModel = ModelSetupViewModel(modelManager: manager)

        XCTAssertEqual(viewModel.selectedModelLocalURL, manager.localURL(for: ModelManager.defaultModel))
    }

    @MainActor
    func testModelSetupViewModelUsesSmallModelWhenRequested() {
        let manager = makeTemporaryModelManager()
        let viewModel = ModelSetupViewModel(modelManager: manager)

        viewModel.useSmallModel()

        XCTAssertEqual(viewModel.selectedModel.id, "qwen3-0.6b-gguf")
        XCTAssertFalse(viewModel.isReady)
        XCTAssertEqual(viewModel.statusText, "Small model download required")
    }

    @MainActor
    func testModelSetupViewModelCanContinueWithoutReadyModel() {
        let manager = makeTemporaryModelManager()
        let viewModel = ModelSetupViewModel(modelManager: manager)

        XCTAssertFalse(viewModel.allowsDashboardWithoutReadyModel)

        viewModel.continueWithoutModel()

        XCTAssertTrue(viewModel.allowsDashboardWithoutReadyModel)
        XCTAssertEqual(viewModel.statusText, "Using fallback planner until a model is ready.")
    }

    @MainActor
    func testModelSetupViewModelIgnoresSelectionAndRoutingChangesWhileDownloading() {
        let manager = makeTemporaryModelManager()
        let viewModel = ModelSetupViewModel(modelManager: manager)
        viewModel.isDownloading = true

        viewModel.useSmallModel()
        viewModel.continueWithoutModel()

        XCTAssertEqual(viewModel.selectedModel, ModelManager.defaultModel)
        XCTAssertFalse(viewModel.allowsDashboardWithoutReadyModel)
        XCTAssertEqual(viewModel.statusText, "Model download required")
    }

    @MainActor
    func testDownloadSelectedModelMarksReadyAfterSuccessfulDownload() async throws {
        let manager = makeTemporaryModelManager()
        let viewModel = ModelSetupViewModel(modelManager: manager) { model in
            try manager.ensureModelDirectoryExists()
            try Data("GGUF test model".utf8).write(to: manager.localURL(for: model))
        }

        try await viewModel.downloadSelectedModel()

        XCTAssertFalse(viewModel.isDownloading)
        XCTAssertTrue(viewModel.isReady)
        XCTAssertEqual(viewModel.statusText, "Model ready")
    }

    @MainActor
    func testDownloadSelectedModelSurfacesFailureAndDoesNotMarkReady() async {
        let manager = makeTemporaryModelManager()
        let viewModel = ModelSetupViewModel(modelManager: manager) { _ in
            throw TestDownloadError.failed
        }

        do {
            try await viewModel.downloadSelectedModel()
            XCTFail("Expected download failure.")
        } catch {
            XCTAssertEqual(error as? TestDownloadError, .failed)
        }

        XCTAssertFalse(viewModel.isDownloading)
        XCTAssertFalse(viewModel.isReady)
        XCTAssertTrue(viewModel.statusText.contains("Download failed"))
    }

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

    func testReportsEmptyLocalModelAsNotReady() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory)
        try manager.ensureModelDirectoryExists()
        FileManager.default.createFile(atPath: manager.localURL(for: ModelManager.defaultModel).path, contents: Data())

        XCTAssertFalse(manager.isModelReady(ModelManager.defaultModel))
    }

    func testReportsNonGGUFLocalModelAsNotReady() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory)
        try manager.ensureModelDirectoryExists()
        try Data("not a model".utf8).write(to: manager.localURL(for: ModelManager.defaultModel))

        XCTAssertFalse(manager.isModelReady(ModelManager.defaultModel))
    }

    @MainActor
    func testDownloadRejectsNon2xxHTTPResponseWithoutMarkingModelReady() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let temporaryDownloadURL = tempDirectory.appending(path: "download.gguf")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        try Data("GGUF test model".utf8).write(to: temporaryDownloadURL)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory) { url in
            let response = HTTPURLResponse(
                url: url,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (temporaryDownloadURL, response)
        }

        do {
            try await manager.download(ModelManager.defaultModel)
            XCTFail("Expected non-2xx response to be rejected.")
        } catch {
            XCTAssertEqual(error as? ModelDownloadError, .unsuccessfulResponse(statusCode: 503))
        }

        XCTAssertFalse(manager.isModelReady(ModelManager.defaultModel))
    }

    @MainActor
    func testDownloadRejectsNonGGUFContentWithoutMarkingModelReady() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let temporaryDownloadURL = tempDirectory.appending(path: "download.gguf")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        try Data("not a model".utf8).write(to: temporaryDownloadURL)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory) { url in
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (temporaryDownloadURL, response)
        }

        do {
            try await manager.download(ModelManager.defaultModel)
            XCTFail("Expected non-GGUF content to be rejected.")
        } catch {
            XCTAssertEqual(error as? ModelDownloadError, .invalidDownloadedFile)
        }

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

    private func makeTemporaryModelManager() -> ModelManager {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        return ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory)
    }
}

private enum TestDownloadError: Error, Equatable {
    case failed
}
