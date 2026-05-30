import Observation

@MainActor
@Observable
final class ModelSetupViewModel {
    private let modelManager: ModelManager

    var selectedModel: ModelMetadata
    var isReady: Bool
    var statusText: String
    var allowsDashboardWithoutReadyModel = false

    init(modelManager: ModelManager = ModelManager(), selectedModel: ModelMetadata = ModelManager.defaultModel) {
        self.modelManager = modelManager
        let selectedModelIsReady = modelManager.isModelReady(selectedModel)
        self.selectedModel = selectedModel
        isReady = selectedModelIsReady
        statusText = selectedModelIsReady ? "Model ready" : "Model download required"
    }

    func useSmallModel() {
        selectedModel = ModelManager.smallFallbackModel
        isReady = modelManager.isModelReady(selectedModel)
        statusText = isReady ? "Model ready" : "Small model download required"
    }

    func continueWithoutModel() {
        allowsDashboardWithoutReadyModel = true
        statusText = "Using fallback planner until a model is ready."
    }
}
