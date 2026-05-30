import Foundation

enum LocalLLMError: Error, Equatable {
    case runtimeUnavailable
    case modelFileMissing
    case generationFailed
}

struct LocalLLMService: TextGenerating {
    var modelURL: URL?

    init(modelURL: URL? = nil) {
        self.modelURL = modelURL
    }

    func generateText(prompt: String) async throws -> String {
        #if canImport(llama)
        return try await LlamaTextRuntime(modelURL: modelURL).generate(prompt: prompt)
        #else
        throw LocalLLMError.runtimeUnavailable
        #endif
    }
}

#if canImport(llama)
import llama

private struct LlamaTextRuntime {
    let modelURL: URL?

    func generate(prompt: String) async throws -> String {
        guard let modelURL, FileManager.default.fileExists(atPath: modelURL.path) else {
            throw LocalLLMError.modelFileMissing
        }
        throw LocalLLMError.generationFailed
    }
}
#endif
