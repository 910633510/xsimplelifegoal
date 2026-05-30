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
    typealias DownloadProgressHandler = (Double) -> Void
    typealias DownloadFile = @MainActor (URL, @escaping DownloadProgressHandler) async throws -> (URL, URLResponse)

    static let defaultModel = ModelMetadata(
        id: "qwen3-1.7b-gguf",
        displayName: "Goal Planner AI",
        remoteURL: URL(string: "http://134.209.74.21/models/Qwen3-1.7B-Q8_0.gguf")!,
        localFilename: "Qwen3-1.7B-Q8_0.gguf",
        approximateBytes: 1_830_000_000,
        status: .notDownloaded
    )

    static let smallFallbackModel = ModelMetadata(
        id: "qwen3-0.6b-gguf",
        displayName: "Goal Planner AI Lite",
        remoteURL: URL(string: "http://134.209.74.21/models/Qwen3-0.6B-Q8_0.gguf")!,
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
        self.downloadFile = downloadFile ?? { url, reportProgress in
            try await ProgressReportingModelDownloader().download(from: url, progress: reportProgress)
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
    func download(_ model: ModelMetadata, progress: @escaping DownloadProgressHandler = { _ in }) async throws {
        try ensureModelDirectoryExists()
        let (temporaryURL, response) = try await downloadFile(model.remoteURL, progress)
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

private final class ProgressReportingModelDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private var continuation: CheckedContinuation<(URL, URLResponse), Error>?
    private var downloadedFileURL: URL?
    private var downloadedResponse: URLResponse?
    private var session: URLSession?
    private var progressHandler: ModelManager.DownloadProgressHandler = { _ in }

    @MainActor
    func download(from url: URL, progress: @escaping ModelManager.DownloadProgressHandler) async throws -> (URL, URLResponse) {
        progressHandler = progress
        let delegateQueue = OperationQueue.main
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        self.session = session
        defer { session.invalidateAndCancel() }
        let result = try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            session.downloadTask(with: url).resume()
        }
        return result
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = min(max(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite), 0), 1)
        progressHandler(progress)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard continuation != nil else { return }
        do {
            let temporaryURL = FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString)
                .appendingPathExtension("download")
            try? FileManager.default.removeItem(at: temporaryURL)
            try FileManager.default.moveItem(at: location, to: temporaryURL)
            downloadedFileURL = temporaryURL
            downloadedResponse = downloadTask.response
        } catch {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let continuation else { return }
        defer { self.continuation = nil }

        if let error {
            continuation.resume(throwing: error)
            return
        }

        guard let downloadedFileURL, let downloadedResponse else {
            continuation.resume(throwing: ModelDownloadError.invalidDownloadedFile)
            return
        }

        continuation.resume(returning: (downloadedFileURL, downloadedResponse))
    }
}
