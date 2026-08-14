import CryptoKit
import Foundation
import os

/// Provides the on-device model without making it part of the application bundle.
protocol LLMModelStore: Sendable {
    /// Returns a model-shaped file already present on the device, if any.
    var existingModelURL: URL? { get }

    /// Returns a verified model, downloading it when necessary.
    func prepareModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL
}

enum LLMModelStoreError: Error, LocalizedError {
    case invalidModel
    case invalidResponse(Int)
    case downloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidModel:
            "The downloaded model failed integrity verification."
        case let .invalidResponse(statusCode):
            "Model download returned HTTP \(statusCode)."
        case let .downloadFailed(reason):
            "Model download failed: \(reason)"
        }
    }
}

/// Persistent model store backed by Application Support and URLSession downloads.
final class LiveLLMModelStore: LLMModelStore, @unchecked Sendable {
    static let shared = LiveLLMModelStore()

    private let fileManager: FileManager
    private let bundledModelURL: URL?
    private let downloadedModelURL: URL
    private let modelDownloadURL: URL
    private let expectedSizeBytes: UInt64
    private let expectedSHA256: String
    private let lock = OSAllocatedUnfairLock()
    private var activeDownload: Task<URL, Error>?

    init(
        fileManager: FileManager = .default,
        bundledModelURL: URL? = LLMConfiguration.bundledModelURL,
        downloadedModelURL: URL = LLMConfiguration.downloadedModelURL,
        modelDownloadURL: URL = LLMConfiguration.modelDownloadURL,
        expectedSizeBytes: UInt64 = LLMConfiguration.modelSizeBytes,
        expectedSHA256: String = LLMConfiguration.modelSHA256,
    ) {
        self.fileManager = fileManager
        self.bundledModelURL = bundledModelURL
        self.downloadedModelURL = downloadedModelURL
        self.modelDownloadURL = modelDownloadURL
        self.expectedSizeBytes = expectedSizeBytes
        self.expectedSHA256 = expectedSHA256
    }

    var existingModelURL: URL? {
        if let bundledModelURL, hasExpectedFileShape(at: bundledModelURL) {
            return bundledModelURL
        }

        if hasExpectedFileShape(at: downloadedModelURL) {
            return downloadedModelURL
        }
        return nil
    }

    func prepareModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL {
        if let existingURL = existingModelURL, isVerifiedModel(at: existingURL) {
            progressHandler(0.25)
            return existingURL
        }

        let task: Task<URL, Error> = lock.withLock {
            if let activeDownload {
                return activeDownload
            }

            let operation = LLMModelDownloadOperation(
                sourceURL: modelDownloadURL,
                destinationURL: downloadedModelURL,
                fileManager: fileManager,
                expectedSizeBytes: expectedSizeBytes,
                expectedSHA256: expectedSHA256,
            )
            let task = Task {
                try await operation.download(progressHandler: progressHandler)
            }
            activeDownload = task
            return task
        }

        defer {
            lock.withLock {
                activeDownload = nil
            }
        }

        return try await task.value
    }

    private func hasExpectedFileShape(at url: URL) -> Bool {
        guard fileManager.fileExists(atPath: url.path),
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber
        else {
            return false
        }
        return size.uint64Value == expectedSizeBytes
    }

    private func isVerifiedModel(at url: URL) -> Bool {
        guard hasExpectedFileShape(at: url),
              let handle = try? FileHandle(forReadingFrom: url)
        else {
            return false
        }

        defer { try? handle.close() }

        var hasher = SHA256()
        do {
            while let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
                hasher.update(data: chunk)
            }
        } catch {
            return false
        }

        let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        return digest == expectedSHA256
    }
}

private final class LLMModelDownloadOperation: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let sourceURL: URL
    private let destinationURL: URL
    private let fileManager: FileManager
    private let expectedSizeBytes: UInt64
    private let expectedSHA256: String
    private let lock = NSLock()

    private var session: URLSession?
    private var task: URLSessionDownloadTask?
    private var continuation: CheckedContinuation<URL, Error>?
    private var didFinish = false
    private var cancellationRequested = false
    private var progressHandler: (@Sendable (Double) -> Void)?

    init(
        sourceURL: URL,
        destinationURL: URL,
        fileManager: FileManager,
        expectedSizeBytes: UInt64,
        expectedSHA256: String,
    ) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.fileManager = fileManager
        self.expectedSizeBytes = expectedSizeBytes
        self.expectedSHA256 = expectedSHA256
    }

    func download(progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)

                lock.lock()
                self.session = session
                self.continuation = continuation
                self.progressHandler = progressHandler
                let task = session.downloadTask(with: sourceURL)
                self.task = task
                let shouldCancel = cancellationRequested
                lock.unlock()

                if shouldCancel {
                    task.cancel()
                } else {
                    task.resume()
                }
            }
        }, onCancel: { [weak self] in
            self?.cancel()
        })
    }

    private func cancel() {
        lock.lock()
        cancellationRequested = true
        let task = task
        lock.unlock()
        task?.cancel()
    }

    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler?(min(max(fraction, 0), 1) * 0.25)
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let response = downloadTask.response as? HTTPURLResponse else {
                throw LLMModelStoreError.downloadFailed("The server returned an invalid response.")
            }
            guard (200 ..< 300).contains(response.statusCode) else {
                throw LLMModelStoreError.invalidResponse(response.statusCode)
            }

            var directoryURL = destinationURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            var directoryValues = URLResourceValues()
            directoryValues.isExcludedFromBackup = true
            try directoryURL.setResourceValues(directoryValues)

            let partialURL = destinationURL.appendingPathExtension("part")
            try? fileManager.removeItem(at: partialURL)
            try fileManager.moveItem(at: location, to: partialURL)

            guard isVerifiedModel(at: partialURL) else {
                try? fileManager.removeItem(at: partialURL)
                throw LLMModelStoreError.invalidModel
            }

            try? fileManager.removeItem(at: destinationURL)
            try fileManager.moveItem(at: partialURL, to: destinationURL)
            finish(.success(destinationURL))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            finish(.failure(error))
        } else {
            finish(.failure(LLMModelStoreError.downloadFailed("The download did not produce a model file.")))
        }
    }

    private func isVerifiedModel(at url: URL) -> Bool {
        guard fileManager.fileExists(atPath: url.path),
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber,
              size.uint64Value == expectedSizeBytes,
              let handle = try? FileHandle(forReadingFrom: url)
        else {
            return false
        }

        defer { try? handle.close() }

        var hasher = SHA256()
        do {
            while let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
                hasher.update(data: chunk)
            }
        } catch {
            return false
        }

        let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        return digest == expectedSHA256
    }

    private func finish(_ result: Result<URL, Error>) {
        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        didFinish = true
        let continuationToResume = continuation
        continuation = nil
        let sessionToInvalidate = session
        session = nil
        task = nil
        lock.unlock()

        sessionToInvalidate?.finishTasksAndInvalidate()
        continuationToResume?.resume(with: result)
    }
}
