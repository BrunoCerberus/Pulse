import CryptoKit
import Foundation
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

        let preparedURL = try await store.prepareModel { _ in }

        #expect(preparedURL == modelURL)
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
}
