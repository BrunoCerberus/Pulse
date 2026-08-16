import CryptoKit
import Foundation
import os
@testable import Pulse
import Testing

@Suite("LLMModelStore Tests")
struct LLMModelStoreTests {
    @Test("Progress is delivered to every caller sharing a download")
    func broadcastsProgressToAllCallers() {
        let broadcaster = LLMModelProgressBroadcaster()
        let firstValues = OSAllocatedUnfairLock(initialState: [Double]())
        let secondValues = OSAllocatedUnfairLock(initialState: [Double]())

        let firstID = broadcaster.add { progress in
            firstValues.withLock { $0.append(progress) }
        }
        broadcaster.send(0.5)

        _ = broadcaster.add { progress in
            secondValues.withLock { $0.append(progress) }
        }

        #expect(firstValues.withLock { $0 } == [0.5])
        #expect(secondValues.withLock { $0 } == [0.5])

        broadcaster.remove(firstID)
        broadcaster.send(0.75)

        #expect(firstValues.withLock { $0 } == [0.5])
        #expect(secondValues.withLock { $0 } == [0.5, 0.75])
    }

    @Test("Resume data survives a failure that produces none")
    func keepsResumeDataWhenFailureCarriesNone() throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-resume-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directoryURL) }

        let source = try #require(URL(string: "https://example.com/model.gguf"))
        let store = LLMModelResumeDataStore(url: directoryURL.appendingPathComponent("model.resume"))
        let partial = Data("partial download".utf8)
        store.persist(partial, for: source)
        #expect(store.load(for: source) == partial)

        // A cellular rejection fails without resume data; discarding the
        // existing sidecar would restart the whole download from zero.
        store.persist(nil, for: source)
        #expect(store.load(for: source) == partial)
        store.persist(Data(), for: source)
        #expect(store.load(for: source) == partial)

        store.persist(Data("newer partial".utf8), for: source)
        #expect(store.load(for: source) == Data("newer partial".utf8))

        store.remove()
        #expect(store.load(for: source) == nil)
    }

    @Test("A verified local model is reused without downloading")
    func reusesVerifiedLocalModel() async throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-store-\(UUID().uuidString)", isDirectory: true)
        let modelURL = directoryURL.appendingPathComponent("model.gguf")
        let modelData = Data("test model".utf8)
        let checksum = SHA256.hash(data: modelData).map { String(format: "%02x", $0) }.joined()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try modelData.write(to: modelURL)
        defer { try? fileManager.removeItem(at: directoryURL) }

        let modelDownloadURL = try #require(URL(string: "https://example.com/should-not-be-called"))
        let store = LiveLLMModelStore(
            fileManager: fileManager,
            bundledModelURL: nil,
            downloadedModelURL: modelURL,
            modelDownloadURL: modelDownloadURL,
            expectedSizeBytes: UInt64(modelData.count),
            expectedSHA256: checksum,
        )

        let progressValues = OSAllocatedUnfairLock(initialState: [Double]())
        let preparedURL = try await store.prepareModel { progress in
            progressValues.withLock { $0.append(progress) }
        }

        #expect(preparedURL == modelURL)
        #expect(progressValues.withLock { $0 } == [1.0])
    }

    @Test("A partial local model is not considered available")
    func rejectsPartialLocalModel() throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-store-\(UUID().uuidString)", isDirectory: true)
        let modelURL = directoryURL.appendingPathComponent("model.gguf")
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try Data("partial".utf8).write(to: modelURL)
        defer { try? fileManager.removeItem(at: directoryURL) }

        let store = LiveLLMModelStore(
            fileManager: fileManager,
            bundledModelURL: nil,
            downloadedModelURL: modelURL,
            expectedSizeBytes: 999,
            expectedSHA256: String(repeating: "0", count: SHA256.Digest.byteCount * 2),
        )

        #expect(store.existingModelURL == nil)
    }

    @Test("A same-sized corrupt local model is not considered available")
    func rejectsCorruptModelWithExpectedSize() throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-store-\(UUID().uuidString)", isDirectory: true)
        let modelURL = directoryURL.appendingPathComponent("model.gguf")
        let modelData = Data("bad!".utf8)
        let expectedChecksum = SHA256.hash(data: Data("good".utf8)).map { String(format: "%02x", $0) }.joined()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try modelData.write(to: modelURL)
        defer { try? fileManager.removeItem(at: directoryURL) }

        let store = LiveLLMModelStore(
            fileManager: fileManager,
            bundledModelURL: nil,
            downloadedModelURL: modelURL,
            expectedSizeBytes: UInt64(modelData.count),
            expectedSHA256: expectedChecksum,
        )

        #expect(store.existingModelURL == nil)
    }

    @Test("Every store error carries a localized description")
    func errorsAreLocalized() {
        let errors: [LLMModelStoreError] = [
            .invalidModel,
            .invalidResponse(503),
            .insufficientStorage,
            .networkRestricted,
            .downloadFailed,
        ]

        for error in errors {
            let description = error.errorDescription
            #expect(description?.isEmpty == false)
            // Localized copy resolves through AppLocalization, so a raw key
            // leaking through means the strings files are missing an entry.
            #expect(description?.hasPrefix("llm.error.") == false)
        }
        #expect(LLMModelStoreError.invalidResponse(503).errorDescription?.contains("503") == true)
    }

    @Test("A verified model writes a record that avoids rehashing")
    func reusesVerificationRecordAcrossLookups() throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-store-\(UUID().uuidString)", isDirectory: true)
        let modelURL = directoryURL.appendingPathComponent("model.gguf")
        let modelData = Data("test model".utf8)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try modelData.write(to: modelURL)
        defer { try? fileManager.removeItem(at: directoryURL) }

        let checksum = SHA256.hash(data: modelData).map { String(format: "%02x", $0) }.joined()
        let store = LiveLLMModelStore(
            fileManager: fileManager,
            bundledModelURL: nil,
            downloadedModelURL: modelURL,
            expectedSizeBytes: UInt64(modelData.count),
            expectedSHA256: checksum,
        )

        #expect(store.existingModelURL == modelURL)
        let recordURL = modelURL.appendingPathExtension("verified")
        #expect(fileManager.fileExists(atPath: recordURL.path))

        // Second lookup is served from the record rather than a fresh hash.
        #expect(store.existingModelURL == modelURL)

        // A record that no longer matches the file must not be trusted.
        try Data("tampered!!".utf8).write(to: modelURL)
        #expect(store.existingModelURL == nil)
        #expect(!fileManager.fileExists(atPath: recordURL.path))
    }

    @Test("Concurrent callers share one download and each receives progress")
    func sharesDownloadAcrossConcurrentCallers() async throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-store-\(UUID().uuidString)", isDirectory: true)
        let modelURL = directoryURL.appendingPathComponent("model.gguf")
        let modelData = Data("test model".utf8)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try modelData.write(to: modelURL)
        defer { try? fileManager.removeItem(at: directoryURL) }

        let checksum = SHA256.hash(data: modelData).map { String(format: "%02x", $0) }.joined()
        let store = LiveLLMModelStore(
            fileManager: fileManager,
            bundledModelURL: nil,
            downloadedModelURL: modelURL,
            expectedSizeBytes: UInt64(modelData.count),
            expectedSHA256: checksum,
        )

        let first = OSAllocatedUnfairLock(initialState: [Double]())
        let second = OSAllocatedUnfairLock(initialState: [Double]())
        async let firstURL = store.prepareModel { value in first.withLock { $0.append(value) } }
        async let secondURL = store.prepareModel { value in second.withLock { $0.append(value) } }
        let results = try await [firstURL, secondURL]

        #expect(results == [modelURL, modelURL])
        #expect(first.withLock { $0 }.last == 1.0)
        #expect(second.withLock { $0 }.last == 1.0)
    }

    @Test("Insufficient storage is reported before starting a download")
    func rejectsDownloadWhenStorageIsInsufficient() async throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-store-\(UUID().uuidString)", isDirectory: true)
        let modelURL = directoryURL.appendingPathComponent("model.gguf")
        defer { try? fileManager.removeItem(at: directoryURL) }

        let store = try LiveLLMModelStore(
            fileManager: fileManager,
            bundledModelURL: nil,
            downloadedModelURL: modelURL,
            modelDownloadURL: #require(URL(string: "https://example.com/should-not-be-called")),
            expectedSizeBytes: 4,
            expectedSHA256: String(repeating: "0", count: SHA256.Digest.byteCount * 2),
            minimumFreeSpaceBytes: 5,
            availableCapacityProvider: { _ in 4 },
        )

        do {
            _ = try await store.prepareModel { _ in }
            Issue.record("Expected the storage check to fail before downloading")
        } catch let error as LLMModelStoreError {
            #expect(error == .insufficientStorage)
        }
    }

    @Test("An orphaned partial file is removed before the storage check")
    func removesOrphanedPartialFileBeforeStorageCheck() async throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-store-\(UUID().uuidString)", isDirectory: true)
        let modelURL = directoryURL.appendingPathComponent("model.gguf")
        let partialURL = modelURL.appendingPathExtension("part")
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try Data("orphaned partial".utf8).write(to: partialURL)
        defer { try? fileManager.removeItem(at: directoryURL) }

        let partialWasPresentDuringCapacityCheck = OSAllocatedUnfairLock(initialState: true)
        let capacityCheckPath = OSAllocatedUnfairLock(initialState: "")
        let partialPath = partialURL.path
        let downloadURL = try #require(URL(string: "https://example.com/should-not-be-called"))
        let store = LiveLLMModelStore(
            fileManager: fileManager,
            bundledModelURL: nil,
            downloadedModelURL: modelURL,
            modelDownloadURL: downloadURL,
            expectedSizeBytes: 4,
            expectedSHA256: String(repeating: "0", count: SHA256.Digest.byteCount * 2),
            minimumFreeSpaceBytes: 5,
            availableCapacityProvider: { url in
                capacityCheckPath.withLock { $0 = url.path }
                partialWasPresentDuringCapacityCheck.withLock {
                    $0 = FileManager.default.fileExists(atPath: partialPath)
                }
                return 4
            },
        )

        do {
            _ = try await store.prepareModel { _ in }
            Issue.record("Expected the storage check to fail before downloading")
        } catch let error as LLMModelStoreError {
            #expect(error == .insufficientStorage)
        }

        #expect(!partialWasPresentDuringCapacityCheck.withLock { $0 })
        #expect(!fileManager.fileExists(atPath: partialURL.path))
        #expect(capacityCheckPath.withLock { $0 } == directoryURL.path)
    }
}
