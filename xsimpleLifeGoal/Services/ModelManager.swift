import Foundation

struct ModelManager {
    static let defaultModel = ModelMetadata(
        id: "qwen3-1.7b-gguf",
        displayName: "Qwen3 1.7B GGUF",
        remoteURL: URL(string: "https://huggingface.co/Qwen/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q8_0.gguf")!,
        localFilename: "Qwen3-1.7B-Q8_0.gguf",
        approximateBytes: 1_830_000_000,
        status: .notDownloaded
    )

    static let smallFallbackModel = ModelMetadata(
        id: "qwen3-0.6b-gguf",
        displayName: "Qwen3 0.6B GGUF",
        remoteURL: URL(string: "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf")!,
        localFilename: "Qwen3-0.6B-Q8_0.gguf",
        approximateBytes: 639_000_000,
        status: .notDownloaded
    )

    private let fileManager: FileManager
    private let applicationSupportDirectory: URL

    init(fileManager: FileManager = .default, applicationSupportDirectory: URL? = nil) {
        self.fileManager = fileManager
        if let applicationSupportDirectory {
            self.applicationSupportDirectory = applicationSupportDirectory
        } else {
            self.applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        }
    }

    func localURL(for model: ModelMetadata) -> URL {
        applicationSupportDirectory
            .appending(path: "Models", directoryHint: .isDirectory)
            .appending(path: model.localFilename)
    }

    func isModelReady(_ model: ModelMetadata) -> Bool {
        fileManager.fileExists(atPath: localURL(for: model).path)
    }

    func ensureModelDirectoryExists() throws {
        try fileManager.createDirectory(
            at: applicationSupportDirectory.appending(path: "Models", directoryHint: .isDirectory),
            withIntermediateDirectories: true
        )
    }
}
