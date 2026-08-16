import CryptoKit
import Foundation
import os

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

/// Sidecar holding a partial download so an interrupted transfer can resume.
struct LLMModelResumeDataStore: @unchecked Sendable {
    private struct Envelope: Codable {
        let sourceURL: URL
        let data: Data
    }

    private let url: URL
    private let fileManager: FileManager

    init(url: URL, fileManager: FileManager = .default) {
        self.url = url
        self.fileManager = fileManager
    }

    /// Returns the stored partial only when it belongs to `sourceURL`. A pinned
    /// model revision change leaves sidecars pointing at the old URL, and
    /// resuming those would fail on every retry forever.
    func load(for sourceURL: URL) -> Data? {
        guard let contents = try? Data(contentsOf: url),
              let envelope = try? JSONDecoder().decode(Envelope.self, from: contents)
        else {
            remove()
            return nil
        }
        guard envelope.sourceURL == sourceURL, !envelope.data.isEmpty else {
            remove()
            return nil
        }
        return envelope.data
    }

    /// Stores resume data when the transfer produced some. A failure that
    /// carries none must leave any earlier partial intact — discarding it would
    /// restart a nearly complete download from zero.
    func persist(_ data: Data?, for sourceURL: URL) {
        guard let data, !data.isEmpty else { return }
        let envelope = Envelope(sourceURL: sourceURL, data: data)
        guard let encoded = try? JSONEncoder().encode(envelope) else { return }
        try? encoded.write(to: url, options: .atomic)
    }

    func remove() {
        try? fileManager.removeItem(at: url)
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
    private var activeDownload: ActiveModelDownload?

    init(
        fileManager: FileManager = .default,
        downloadedModelURL: URL = LLMConfiguration.downloadedModelURL,
        resumeDataURL: URL? = nil,
        modelDownloadURL: URL = LLMConfiguration.modelDownloadURL,
        expectedSizeBytes: UInt64 = LLMConfiguration.modelSizeBytes,
        expectedSHA256: String = LLMConfiguration.modelSHA256,
        minimumFreeSpaceBytes: UInt64? = nil,
        availableCapacityProvider: @escaping @Sendable (URL) -> UInt64? = LiveLLMModelStore.availableCapacity,
    ) {
        self.fileManager = fileManager
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
        isVerifiedModel(at: downloadedModelURL) ? downloadedModelURL : nil
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

        // Named distinctly from `self.activeDownload`: older compilers resolve a
        // bare `activeDownload` inside the closure to the constant being
        // declared here rather than to the property.
        let sharedDownload: ActiveModelDownload = lock.withLock {
            if let existing = self.activeDownload {
                return existing
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
            let created = ActiveModelDownload(task: task, progress: progress)
            self.activeDownload = created
            return created
        }

        let progressHandlerID = sharedDownload.progress.add(progressHandler)
        defer {
            sharedDownload.progress.remove(progressHandlerID)
            lock.withLock {
                if self.activeDownload?.id == sharedDownload.id {
                    self.activeDownload = nil
                }
            }
        }

        let modelURL = try await sharedDownload.task.value
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

    /// Verifies the downloaded model, hashing it only when the sidecar record
    /// does not already vouch for this exact file.
    private func isVerifiedModel(at url: URL) -> Bool {
        guard let signature = fileSignature(at: url) else {
            removeVerificationRecord()
            return false
        }

        if let record = readVerificationRecord(),
           record.size == signature.size,
           record.modificationTime == signature.modificationTime,
           record.sha256 == expectedSHA256
        {
            return true
        }

        guard llmModelFileSHA256(at: url) == expectedSHA256 else {
            removeVerificationRecord()
            return false
        }

        writeVerificationRecord(for: signature)
        return true
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

func llmModelFileSHA256(fileManager: FileManager = .default, at url: URL) -> String? {
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
