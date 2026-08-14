import CryptoKit
import Foundation
import os
#if canImport(UIKit)
    import UIKit
#endif

/// Provides the on-device model without making it part of the application bundle.
protocol LLMModelStore: Sendable {
    /// Returns a verified model already present on the device, if any.
    var existingModelURL: URL? { get }

    /// Returns a verified model, downloading it when necessary.
    func prepareModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL
}

enum LLMModelStoreError: Error, LocalizedError, Equatable {
    case invalidModel
    case invalidResponse(Int)
    case insufficientStorage
    case networkRestricted
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidModel:
            AppLocalization.localized("llm.error.model_integrity")
        case let .invalidResponse(statusCode):
            String(format: AppLocalization.localized("llm.error.model_http"), statusCode)
        case .insufficientStorage:
            AppLocalization.localized("llm.error.model_storage")
        case .networkRestricted:
            AppLocalization.localized("llm.error.model_network")
        case .downloadFailed:
            AppLocalization.localized("llm.error.model_download")
        }
    }
}

private struct ModelVerificationRecord: Codable, Equatable {
    let size: UInt64
    let modificationTime: TimeInterval
    let sha256: String
}

private struct ModelFileSignature: Equatable {
    let size: UInt64
    let modificationTime: TimeInterval
}

final class LLMModelProgressBroadcaster: @unchecked Sendable {
    private let lock = NSLock()
    private var handlers: [UUID: @Sendable (Double) -> Void] = [:]
    private var latestProgress: Double?

    @discardableResult
    func add(_ handler: @escaping @Sendable (Double) -> Void) -> UUID {
        let id = UUID()
        let latestProgress = lock.withLock {
            handlers[id] = handler
            return self.latestProgress
        }
        if let latestProgress {
            handler(latestProgress)
        }
        return id
    }

    func remove(_ id: UUID) {
        lock.withLock {
            handlers[id] = nil
        }
    }

    func send(_ progress: Double) {
        let handlers = lock.withLock { () -> [@Sendable (Double) -> Void] in
            latestProgress = progress
            return Array(self.handlers.values)
        }
        handlers.forEach { $0(progress) }
    }
}

private final class ActiveModelDownload: @unchecked Sendable {
    let id = UUID()
    let task: Task<URL, Error>
    let progress: LLMModelProgressBroadcaster

    init(task: Task<URL, Error>, progress: LLMModelProgressBroadcaster) {
        self.task = task
        self.progress = progress
    }
}

/// Persistent model store backed by Application Support and resumable URLSession downloads.
final class LiveLLMModelStore: LLMModelStore, @unchecked Sendable {
    static let shared = LiveLLMModelStore()

    private let fileManager: FileManager
    private let bundledModelURL: URL?
    private let downloadedModelURL: URL
    private let resumeDataURL: URL
    private let verificationURL: URL
    private let partialModelURL: URL
    private let modelDownloadURL: URL
    private let expectedSizeBytes: UInt64
    private let expectedSHA256: String
    private let minimumFreeSpaceBytes: UInt64
    private let availableCapacityProvider: @Sendable (URL) -> UInt64?
    private let lock = OSAllocatedUnfairLock()
    private let verificationLock = NSLock()
    private var bundledVerificationRecord: ModelVerificationRecord?
    private var activeDownload: ActiveModelDownload?

    init(
        fileManager: FileManager = .default,
        bundledModelURL: URL? = LLMConfiguration.bundledModelURL,
        downloadedModelURL: URL = LLMConfiguration.downloadedModelURL,
        resumeDataURL: URL? = nil,
        modelDownloadURL: URL = LLMConfiguration.modelDownloadURL,
        expectedSizeBytes: UInt64 = LLMConfiguration.modelSizeBytes,
        expectedSHA256: String = LLMConfiguration.modelSHA256,
        minimumFreeSpaceBytes: UInt64? = nil,
        availableCapacityProvider: @escaping @Sendable (URL) -> UInt64? = LiveLLMModelStore.availableCapacity,
    ) {
        self.fileManager = fileManager
        self.bundledModelURL = bundledModelURL
        self.downloadedModelURL = downloadedModelURL
        self.resumeDataURL = resumeDataURL ?? downloadedModelURL.appendingPathExtension("resume")
        verificationURL = downloadedModelURL.appendingPathExtension("verified")
        partialModelURL = downloadedModelURL.appendingPathExtension("part")
        self.modelDownloadURL = modelDownloadURL
        self.expectedSizeBytes = expectedSizeBytes
        self.expectedSHA256 = expectedSHA256
        self.minimumFreeSpaceBytes = minimumFreeSpaceBytes ?? expectedSizeBytes + (128 * 1024 * 1024)
        self.availableCapacityProvider = availableCapacityProvider
    }

    var existingModelURL: URL? {
        if let bundledModelURL, isVerifiedModel(at: bundledModelURL) {
            return bundledModelURL
        }

        if isVerifiedModel(at: downloadedModelURL) {
            return downloadedModelURL
        }
        return nil
    }

    func prepareModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let existingURL = await Task.detached(priority: .utility) { [self] in
            existingModelURL
        }.value
        if let existingURL {
            progressHandler(1.0)
            return existingURL
        }

        if lock.withLock({ activeDownload == nil }) {
            do {
                try? fileManager.removeItem(at: partialModelURL)
                try prepareDestinationDirectory()
                try ensureSufficientStorage()
            } catch let error as LLMModelStoreError {
                throw error
            } catch {
                throw LLMModelStoreError.downloadFailed
            }
        }

        let activeDownload: ActiveModelDownload = lock.withLock {
            if let activeDownload {
                return activeDownload
            }

            let progress = LLMModelProgressBroadcaster()
            let operation = LLMModelDownloadOperation(
                sourceURL: modelDownloadURL,
                destinationURL: downloadedModelURL,
                resumeDataURL: resumeDataURL,
                fileManager: fileManager,
                expectedSizeBytes: expectedSizeBytes,
                expectedSHA256: expectedSHA256,
            )
            let task = Task {
                try await operation.download(progressHandler: progress.send)
            }
            let activeDownload = ActiveModelDownload(task: task, progress: progress)
            self.activeDownload = activeDownload
            return activeDownload
        }

        let progressHandlerID = activeDownload.progress.add(progressHandler)
        defer {
            activeDownload.progress.remove(progressHandlerID)
            lock.withLock {
                if self.activeDownload?.id == activeDownload.id {
                    self.activeDownload = nil
                }
            }
        }

        let modelURL = try await activeDownload.task.value
        cacheVerifiedModel(at: modelURL)
        return modelURL
    }

    private func cacheVerifiedModel(at url: URL) {
        guard url == downloadedModelURL, let signature = fileSignature(at: url) else { return }
        writeVerificationRecord(for: signature)
    }

    private func prepareDestinationDirectory() throws {
        var directoryURL = downloadedModelURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        var directoryValues = URLResourceValues()
        directoryValues.isExcludedFromBackup = true
        try directoryURL.setResourceValues(directoryValues)
    }

    private func ensureSufficientStorage() throws {
        let storageURL = downloadedModelURL.deletingLastPathComponent()
        guard let availableCapacity = availableCapacityProvider(storageURL) else { return }
        guard availableCapacity >= minimumFreeSpaceBytes else {
            throw LLMModelStoreError.insufficientStorage
        }
    }

    private func isVerifiedModel(at url: URL) -> Bool {
        guard let signature = fileSignature(at: url) else {
            if url == downloadedModelURL {
                removeVerificationRecord()
            } else if url == bundledModelURL {
                clearBundledVerificationRecord()
            }
            return false
        }

        if url == bundledModelURL,
           let record = readBundledVerificationRecord(),
           record.size == signature.size,
           record.modificationTime == signature.modificationTime,
           record.sha256 == expectedSHA256
        {
            return true
        }

        if url == downloadedModelURL,
           let record = readVerificationRecord(),
           record.size == signature.size,
           record.modificationTime == signature.modificationTime,
           record.sha256 == expectedSHA256
        {
            return true
        }

        guard fileSHA256(at: url) == expectedSHA256 else {
            if url == downloadedModelURL {
                removeVerificationRecord()
            } else if url == bundledModelURL {
                clearBundledVerificationRecord()
            }
            return false
        }

        if url == downloadedModelURL {
            writeVerificationRecord(for: signature)
        } else if url == bundledModelURL {
            cacheBundledVerificationRecord(for: signature)
        }
        return true
    }

    private func cacheBundledVerificationRecord(for signature: ModelFileSignature) {
        verificationLock.lock()
        bundledVerificationRecord = ModelVerificationRecord(
            size: signature.size,
            modificationTime: signature.modificationTime,
            sha256: expectedSHA256,
        )
        verificationLock.unlock()
    }

    private func readBundledVerificationRecord() -> ModelVerificationRecord? {
        verificationLock.lock()
        defer { verificationLock.unlock() }
        return bundledVerificationRecord
    }

    private func clearBundledVerificationRecord() {
        verificationLock.lock()
        bundledVerificationRecord = nil
        verificationLock.unlock()
    }

    private func fileSignature(at url: URL) -> ModelFileSignature? {
        guard fileManager.fileExists(atPath: url.path),
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber,
              size.uint64Value == expectedSizeBytes,
              let modificationDate = attributes[.modificationDate] as? Date
        else {
            return nil
        }
        return ModelFileSignature(size: size.uint64Value, modificationTime: modificationDate.timeIntervalSince1970)
    }

    private func readVerificationRecord() -> ModelVerificationRecord? {
        verificationLock.lock()
        defer { verificationLock.unlock() }
        guard let data = try? Data(contentsOf: verificationURL) else { return nil }
        return try? JSONDecoder().decode(ModelVerificationRecord.self, from: data)
    }

    private func writeVerificationRecord(for signature: ModelFileSignature) {
        let record = ModelVerificationRecord(
            size: signature.size,
            modificationTime: signature.modificationTime,
            sha256: expectedSHA256,
        )
        verificationLock.lock()
        defer { verificationLock.unlock() }
        guard let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: verificationURL, options: .atomic)
    }

    private func removeVerificationRecord() {
        verificationLock.lock()
        defer { verificationLock.unlock() }
        try? fileManager.removeItem(at: verificationURL)
    }

    private static func availableCapacity(at url: URL) -> UInt64? {
        guard let values = try? url.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
        ]) else {
            return nil
        }

        if let capacity = values.volumeAvailableCapacityForImportantUsage, capacity >= 0 {
            return UInt64(capacity)
        }
        if let capacity = values.volumeAvailableCapacity, capacity >= 0 {
            return UInt64(capacity)
        }
        return nil
    }
}

private func fileSHA256(fileManager: FileManager = .default, at url: URL) -> String? {
    guard fileManager.fileExists(atPath: url.path),
          let handle = try? FileHandle(forReadingFrom: url)
    else {
        return nil
    }

    defer { try? handle.close() }

    var hasher = SHA256()
    do {
        while let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
    } catch {
        return nil
    }

    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}

private final class LLMModelDownloadOperation: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let sourceURL: URL
    private let destinationURL: URL
    private let resumeDataURL: URL
    private let fileManager: FileManager
    private let expectedSizeBytes: UInt64
    private let expectedSHA256: String
    private let lock = NSLock()

    private var session: URLSession?
    private var task: URLSessionDownloadTask?
    private var continuation: CheckedContinuation<URL, Error>?
    private var didFinish = false
    private var cancellationRequested = false
    private var pausingForBackground = false
    private var waitingForPauseCancellation = false
    private var foregroundRequested = false
    private var progressHandler: (@Sendable (Double) -> Void)?
    private var observers: [NSObjectProtocol] = []

    init(
        sourceURL: URL,
        destinationURL: URL,
        resumeDataURL: URL,
        fileManager: FileManager,
        expectedSizeBytes: UInt64,
        expectedSHA256: String,
    ) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.resumeDataURL = resumeDataURL
        self.fileManager = fileManager
        self.expectedSizeBytes = expectedSizeBytes
        self.expectedSHA256 = expectedSHA256
    }

    func download(progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL {
        registerLifecycleObservers()
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                lock.lock()
                self.continuation = continuation
                self.progressHandler = progressHandler
                lock.unlock()
                startDownload()
            }
        }, onCancel: { [weak self] in
            self?.cancel()
        })
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.allowsExpensiveNetworkAccess = false
        configuration.allowsConstrainedNetworkAccess = false
        configuration.timeoutIntervalForResource = 24 * 60 * 60
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    private func startDownload() {
        let resumeData = (try? Data(contentsOf: resumeDataURL)).flatMap { $0.isEmpty ? nil : $0 }

        lock.lock()
        guard !didFinish,
              !cancellationRequested,
              !pausingForBackground,
              !waitingForPauseCancellation,
              task == nil
        else {
            lock.unlock()
            return
        }

        let session = makeSession()
        let task = resumeData.map(session.downloadTask(withResumeData:)) ?? session.downloadTask(with: sourceURL)
        self.session = session
        self.task = task
        lock.unlock()

        task.resume()
    }

    private func cancel() {
        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        cancellationRequested = true
        pausingForBackground = true
        let task = task
        let session = session
        self.task = nil
        self.session = nil
        lock.unlock()

        guard let task else {
            finish(.failure(CancellationError()))
            return
        }

        task.cancel { [weak self] _ in
            guard let self else { return }
            removeResumeData()
            session?.finishTasksAndInvalidate()
            finish(.failure(CancellationError()))
        }
    }

    #if canImport(UIKit)
        private func registerLifecycleObservers() {
            let center = NotificationCenter.default
            let backgroundObserver = center.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: nil,
            ) { [weak self] _ in
                self?.pauseForBackground()
            }
            let foregroundObserver = center.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: nil,
            ) { [weak self] _ in
                self?.resumeAfterBackground()
            }
            lock.withLock {
                observers = [backgroundObserver, foregroundObserver]
            }
        }

        private func pauseForBackground() {
            lock.lock()
            guard !didFinish, !cancellationRequested, !pausingForBackground, let task else {
                lock.unlock()
                return
            }
            pausingForBackground = true
            waitingForPauseCancellation = true
            foregroundRequested = false
            let session = session
            self.task = nil
            self.session = nil
            lock.unlock()

            task.cancel { [weak self] resumeData in
                guard let self else { return }
                let shouldPersistResumeData = lock.withLock {
                    !didFinish && !cancellationRequested
                }
                if shouldPersistResumeData {
                    replaceResumeData(with: resumeData)
                } else {
                    removeResumeData()
                }
                session?.finishTasksAndInvalidate()

                lock.lock()
                waitingForPauseCancellation = false
                let shouldResume = foregroundRequested
                    && !didFinish
                    && !cancellationRequested
                if shouldResume {
                    foregroundRequested = false
                    pausingForBackground = false
                }
                lock.unlock()

                if shouldResume {
                    startDownload()
                }
            }
        }

        private func resumeAfterBackground() {
            lock.lock()
            guard !didFinish, !cancellationRequested else {
                lock.unlock()
                return
            }
            foregroundRequested = true
            let shouldStartImmediately = !waitingForPauseCancellation
            if shouldStartImmediately {
                foregroundRequested = false
                pausingForBackground = false
            }
            lock.unlock()
            if shouldStartImmediately {
                startDownload()
            }
        }
    #else
        private func registerLifecycleObservers() {}
    #endif

    private func replaceResumeData(with data: Data?) {
        guard let data, !data.isEmpty else {
            removeResumeData()
            return
        }
        try? data.write(to: resumeDataURL, options: .atomic)
    }

    func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
    ) {
        lock.lock()
        guard task === downloadTask else {
            lock.unlock()
            return
        }
        let progressHandler = progressHandler
        lock.unlock()

        let expectedBytes = totalBytesExpectedToWrite > 0
            ? totalBytesExpectedToWrite
            : Int64(min(expectedSizeBytes, UInt64(Int64.max)))
        guard expectedBytes > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(expectedBytes)
        progressHandler?(min(max(fraction, 0), 1))
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        lock.lock()
        guard task === downloadTask else {
            lock.unlock()
            return
        }
        lock.unlock()

        do {
            guard let response = downloadTask.response as? HTTPURLResponse else {
                throw LLMModelStoreError.downloadFailed
            }
            guard (200 ..< 300).contains(response.statusCode) else {
                removeResumeData()
                throw LLMModelStoreError.invalidResponse(response.statusCode)
            }

            let partialURL = destinationURL.appendingPathExtension("part")
            try? fileManager.removeItem(at: partialURL)
            try fileManager.moveItem(at: location, to: partialURL)

            guard isVerifiedModel(at: partialURL) else {
                try? fileManager.removeItem(at: partialURL)
                removeResumeData()
                throw LLMModelStoreError.invalidModel
            }

            try? fileManager.removeItem(at: destinationURL)
            try fileManager.moveItem(at: partialURL, to: destinationURL)
            finish(.success(destinationURL))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_: URLSession, task completedTask: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        guard task === completedTask else {
            lock.unlock()
            return
        }
        let isPausing = pausingForBackground
        lock.unlock()
        guard !isPausing else { return }

        if let error {
            let nsError = error as NSError
            let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
            replaceResumeData(with: resumeData)
            finish(.failure(map(error: error)))
        } else {
            removeResumeData()
            finish(.failure(LLMModelStoreError.downloadFailed))
        }
    }

    private func isVerifiedModel(at url: URL) -> Bool {
        guard fileManager.fileExists(atPath: url.path),
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber,
              size.uint64Value == expectedSizeBytes
        else {
            return false
        }
        return fileSHA256(fileManager: fileManager, at: url) == expectedSHA256
    }

    private func map(error: Error) -> Error {
        guard let urlError = error as? URLError, urlError.code == .dataNotAllowed else {
            return LLMModelStoreError.downloadFailed
        }
        return LLMModelStoreError.networkRestricted
    }

    private func removeResumeData() {
        try? fileManager.removeItem(at: resumeDataURL)
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
        waitingForPauseCancellation = false
        foregroundRequested = false
        let observersToRemove = observers
        observers.removeAll()
        lock.unlock()

        for observer in observersToRemove {
            NotificationCenter.default.removeObserver(observer)
        }
        if case .success = result {
            removeResumeData()
        }
        sessionToInvalidate?.finishTasksAndInvalidate()
        continuationToResume?.resume(with: result)
    }
}
