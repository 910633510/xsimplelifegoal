import Observation

@MainActor
@Observable
final class ModelSetupViewModel {
    private let modelManager: ModelManager

    var selectedModel: ModelMetadata
    var isReady: Bool
    var statusText: String

    init(modelManager: ModelManager = ModelManager()) {
        self.modelManager = modelManager
        let defaultModel = ModelManager.defaultModel
        let defaultModelIsReady = modelManager.isModelReady(defaultModel)
        selectedModel = defaultModel
        isReady = defaultModelIsReady
        statusText = defaultModelIsReady ? "Model ready" : "Model download required"
    }

    func useSmallModel() {
        selectedModel = ModelManager.smallFallbackModel
        isReady = modelManager.isModelReady(selectedModel)
        statusText = isReady ? "Model ready" : "Small model download required"
    }
}
