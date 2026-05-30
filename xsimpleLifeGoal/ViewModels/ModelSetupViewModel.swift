import Foundation
import Observation

@MainActor
@Observable
final class ModelSetupViewModel {
    private let modelManager: ModelManager
    private let downloadSelectedModelAction: @MainActor (ModelMetadata, @escaping ModelManager.DownloadProgressHandler) async throws -> Void

    var selectedModel: ModelMetadata
    var isReady: Bool
    var isDownloading = false
    var downloadProgress: Double?
    var statusText: String
    var allowsDashboardWithoutReadyModel = false

    var downloadProgressText: String {
        guard let downloadProgress else { return "" }
        let percent = Int((downloadProgress * 100).rounded())
        return "\(percent)%"
    }

    var selectedModelLocalURL: URL {
        modelManager.localURL(for: selectedModel)
    }

    init(
        modelManager: ModelManager = ModelManager(),
        selectedModel: ModelMetadata = ModelManager.defaultModel,
        downloadSelectedModelAction: (@MainActor (ModelMetadata, @escaping ModelManager.DownloadProgressHandler) async throws -> Void)? = nil
    ) {
        self.modelManager = modelManager
        self.downloadSelectedModelAction = downloadSelectedModelAction ?? { model, reportProgress in
            try await modelManager.download(model, progress: reportProgress)
        }
        let selectedModelIsReady = modelManager.isModelReady(selectedModel)
        self.selectedModel = selectedModel
        isReady = selectedModelIsReady
        statusText = selectedModelIsReady ? "Model ready" : "Model download required"
    }

    func useSmallModel() {
        guard !isDownloading else { return }
        selectedModel = ModelManager.smallFallbackModel
        isReady = modelManager.isModelReady(selectedModel)
        statusText = isReady ? "Model ready" : "Small model download required"
    }

    func continueWithoutModel() {
        guard !isDownloading else { return }
        allowsDashboardWithoutReadyModel = true
        statusText = "Using fallback planner until a model is ready."
    }

    func downloadSelectedModel() async throws {
        let model = selectedModel
        isDownloading = true
        isReady = false
        downloadProgress = 0
        statusText = "Downloading \(model.displayName)..."
        do {
            try await downloadSelectedModelAction(model) { [weak self] progress in
                self?.downloadProgress = min(max(progress, 0), 1)
            }
            guard modelManager.isModelReady(model) else {
                throw ModelDownloadError.invalidDownloadedFile
            }
            isReady = true
            downloadProgress = 1
            statusText = "Model ready"
            isDownloading = false
        } catch {
            isReady = false
            downloadProgress = nil
            statusText = "Download failed: \(error.localizedDescription)"
            isDownloading = false
            throw error
        }
    }
}
