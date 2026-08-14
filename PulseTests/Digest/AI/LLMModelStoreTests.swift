import CryptoKit
import Foundation
import os
@testable import Pulse
import Testing

@Suite("LLMModelStore Tests")
struct LLMModelStoreTests {
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
}
