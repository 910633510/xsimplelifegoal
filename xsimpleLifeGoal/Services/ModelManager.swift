import Foundation

enum ModelDownloadError: LocalizedError, Equatable {
    case unsuccessfulResponse(statusCode: Int)
    case invalidDownloadedFile

    var errorDescription: String? {
        switch self {
        case let .unsuccessfulResponse(statusCode):
            "Model download failed with HTTP status \(statusCode)."
        case .invalidDownloadedFile:
            "Downloaded model file is invalid."
        }
    }
}

struct ModelManager {
    typealias DownloadFile = @MainActor (URL) async throws -> (URL, URLResponse)

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
    private let downloadFile: DownloadFile

    init(fileManager: FileManager = .default, applicationSupportDirectory: URL? = nil, downloadFile: DownloadFile? = nil) {
        self.fileManager = fileManager
        if let applicationSupportDirectory {
            self.applicationSupportDirectory = applicationSupportDirectory
        } else {
            self.applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        }
        self.downloadFile = downloadFile ?? { url in
            try await URLSession.shared.download(from: url)
        }
    }

    func localURL(for model: ModelMetadata) -> URL {
        applicationSupportDirectory
            .appending(path: "Models", directoryHint: .isDirectory)
            .appending(path: model.localFilename)
    }

    func isModelReady(_ model: ModelMetadata) -> Bool {
        isValidDownloadedModel(at: localURL(for: model))
    }

    func ensureModelDirectoryExists() throws {
        try fileManager.createDirectory(
            at: applicationSupportDirectory.appending(path: "Models", directoryHint: .isDirectory),
            withIntermediateDirectories: true
        )
    }

    @MainActor
    func download(_ model: ModelMetadata) async throws {
        try ensureModelDirectoryExists()
        let (temporaryURL, response) = try await downloadFile(model.remoteURL)
        do {
            try validate(response: response)
            guard isValidDownloadedModel(at: temporaryURL) else {
                throw ModelDownloadError.invalidDownloadedFile
            }
        } catch {
            try? fileManager.removeItem(at: temporaryURL)
            throw error
        }

        let destinationURL = localURL(for: model)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ModelDownloadError.unsuccessfulResponse(statusCode: httpResponse.statusCode)
        }
    }

    private func isValidDownloadedModel(at url: URL) -> Bool {
        guard fileManager.fileExists(atPath: url.path),
              let fileHandle = try? FileHandle(forReadingFrom: url),
              let header = try? fileHandle.read(upToCount: 4) else {
            return false
        }
        try? fileHandle.close()
        return header == Data("GGUF".utf8)
    }
}
