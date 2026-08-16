import CryptoKit
import Foundation
import os
@testable import Pulse
import Testing
import UIKit

/// Serves canned responses so the download path can be exercised without a network.
final class StubModelDownloadProtocol: URLProtocol, @unchecked Sendable {
    struct Response {
        var statusCode: Int
        var body: Data
        var error: URLError?
        /// Streams the body in chunks, pausing between them so the transfer can
        /// be observed mid-flight (background pause, cancellation, progress).
        var chunkCount = 1
        var chunkDelay: TimeInterval = 0
    }

    private nonisolated(unsafe) static var response = Response(statusCode: 200, body: Data(), error: nil)
    private nonisolated(unsafe) static var requestedURLs: [URL] = []
    private static let lock = NSLock()
    private let isStopped = OSAllocatedUnfairLock(initialState: false)

    static func configure(_ response: Response) {
        lock.withLock {
            self.response = response
            requestedURLs = []
        }
    }

    static var recordedURLs: [URL] {
        lock.withLock { requestedURLs }
    }

    // swiftlint:disable static_over_final_class - URLProtocol declares these as class methods.
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    // swiftlint:enable static_over_final_class

    override func startLoading() {
        let response = Self.lock.withLock { () -> Response in
            if let url = request.url {
                Self.requestedURLs.append(url)
            }
            return Self.response
        }

        if let error = response.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Length": String(response.body.count)],
        )!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)

        let chunkSize = max(1, response.body.count / max(1, response.chunkCount))
        var offset = 0
        while offset < response.body.count {
            if isStopped.withLock({ $0 }) {
                return
            }
            let end = min(offset + chunkSize, response.body.count)
            client?.urlProtocol(self, didLoad: response.body[offset ..< end])
            offset = end
            if response.chunkDelay > 0, offset < response.body.count {
                Thread.sleep(forTimeInterval: response.chunkDelay)
            }
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        isStopped.withLock { $0 = true }
    }
}

@Suite("LLMModelDownloadOperation Tests", .serialized)
struct LLMModelDownloadOperationTests {
    private struct Fixture {
        let directoryURL: URL
        let destinationURL: URL
        let resumeDataURL: URL
        let sourceURL: URL
        let body: Data
        let checksum: String
    }

    private func makeFixture() throws -> Fixture {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("pulse-llm-download-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let body = Data("pulse model payload".utf8)
        return try Fixture(
            directoryURL: directoryURL,
            destinationURL: directoryURL.appendingPathComponent("model.gguf"),
            resumeDataURL: directoryURL.appendingPathComponent("model.resume"),
            sourceURL: #require(URL(string: "https://example.com/model.gguf")),
            body: body,
            checksum: SHA256.hash(data: body).map { String(format: "%02x", $0) }.joined(),
        )
    }

    private func makeOperation(_ fixture: Fixture, checksum: String? = nil) -> LLMModelDownloadOperation {
        LLMModelDownloadOperation(
            sourceURL: fixture.sourceURL,
            destinationURL: fixture.destinationURL,
            resumeDataURL: fixture.resumeDataURL,
            fileManager: .default,
            expectedSizeBytes: UInt64(fixture.body.count),
            expectedSHA256: checksum ?? fixture.checksum,
            protocolClasses: [StubModelDownloadProtocol.self],
        )
    }

    @Test("A successful download is verified and moved into place")
    func downloadsAndVerifiesModel() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }
        StubModelDownloadProtocol.configure(.init(statusCode: 200, body: fixture.body, error: nil))

        let progress = ProgressCollector()
        let url = try await makeOperation(fixture).download { progress.append($0) }
        let written = try Data(contentsOf: fixture.destinationURL)

        #expect(url == fixture.destinationURL)
        #expect(written == fixture.body)
        #expect(!FileManager.default.fileExists(atPath: fixture.resumeDataURL.path))
        #expect(!FileManager.default.fileExists(atPath: fixture.destinationURL.appendingPathExtension("part").path))
        #expect(progress.value.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    @Test("A payload failing its checksum is rejected and discarded")
    func rejectsChecksumMismatch() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }
        StubModelDownloadProtocol.configure(.init(statusCode: 200, body: fixture.body, error: nil))

        let wrongChecksum = String(repeating: "a", count: SHA256.Digest.byteCount * 2)
        await #expect(throws: LLMModelStoreError.invalidModel) {
            _ = try await makeOperation(fixture, checksum: wrongChecksum).download { _ in }
        }

        #expect(!FileManager.default.fileExists(atPath: fixture.destinationURL.path))
        #expect(!FileManager.default.fileExists(atPath: fixture.destinationURL.appendingPathExtension("part").path))
    }

    @Test("A non-2xx response is surfaced and clears resume data")
    func reportsHTTPFailure() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }
        try Data("stale".utf8).write(to: fixture.resumeDataURL)
        StubModelDownloadProtocol.configure(.init(statusCode: 404, body: Data(), error: nil))

        await #expect(throws: LLMModelStoreError.invalidResponse(404)) {
            _ = try await makeOperation(fixture).download { _ in }
        }

        #expect(!FileManager.default.fileExists(atPath: fixture.resumeDataURL.path))
    }

    @Test("A transient failure keeps stored resume data for the next attempt")
    func keepsResumeDataOnTransientFailure() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }

        let resumeStore = LLMModelResumeDataStore(url: fixture.resumeDataURL)
        let partial = Data("partial bytes".utf8)
        resumeStore.persist(partial, for: fixture.sourceURL)
        StubModelDownloadProtocol.configure(.init(statusCode: 200, body: Data(), error: URLError(.dataNotAllowed)))

        await #expect(throws: LLMModelStoreError.networkRestricted) {
            _ = try await makeOperation(fixture).download { _ in }
        }

        #expect(resumeStore.load(for: fixture.sourceURL) == partial)
    }

    @Test("Backgrounding mid-transfer pauses and foregrounding completes the download")
    func pausesOnBackgroundAndResumesOnForeground() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }
        StubModelDownloadProtocol.configure(
            .init(statusCode: 200, body: fixture.body, error: nil, chunkCount: 8, chunkDelay: 0.05),
        )

        let operation = makeOperation(fixture)
        async let result = operation.download { _ in }

        // Let the transfer start before driving the lifecycle notifications the
        // operation observes.
        try await Task.sleep(nanoseconds: 100_000_000)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try await Task.sleep(nanoseconds: 150_000_000)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        let url = try await result
        let written = try Data(contentsOf: fixture.destinationURL)

        #expect(url == fixture.destinationURL)
        #expect(written == fixture.body)
        #expect(!FileManager.default.fileExists(atPath: fixture.resumeDataURL.path))
    }

    @Test("Backgrounding after the payload arrives still commits the download")
    func commitSurvivesBackgrounding() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }
        StubModelDownloadProtocol.configure(.init(statusCode: 200, body: fixture.body, error: nil))

        let operation = makeOperation(fixture)
        async let result = operation.download { _ in }

        // Verification runs asynchronously; a pause landing in that window must
        // not restart the transfer or discard the finished file.
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        let url = try await result
        #expect(url == fixture.destinationURL)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.body)
    }

    @Test("Cancelling the download clears resume data and stops the transfer")
    func cancellationDiscardsPartialState() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }
        StubModelDownloadProtocol.configure(
            .init(statusCode: 200, body: fixture.body, error: nil, chunkCount: 8, chunkDelay: 0.1),
        )

        let operation = makeOperation(fixture)
        let task = Task { try await operation.download { _ in } }
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        await #expect(throws: (any Error).self) { try await task.value }
        #expect(!FileManager.default.fileExists(atPath: fixture.resumeDataURL.path))
        #expect(!FileManager.default.fileExists(atPath: fixture.destinationURL.path))
    }

    @Test("Progress is throttled and never moves backwards")
    func reportsMonotonicThrottledProgress() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }
        StubModelDownloadProtocol.configure(
            .init(statusCode: 200, body: fixture.body, error: nil, chunkCount: 8, chunkDelay: 0.01),
        )

        let progress = ProgressCollector()
        _ = try await makeOperation(fixture).download { progress.append($0) }

        let values = progress.value
        #expect(values == values.sorted())
        #expect(zip(values, values.dropFirst()).allSatisfy { $1 - $0 >= 0.01 - .ulpOfOne })
    }

    @Test("Resume data recorded for another source URL is discarded")
    func discardsResumeDataFromAnotherSource() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directoryURL) }

        let resumeStore = LLMModelResumeDataStore(url: fixture.resumeDataURL)
        let previousRevision = try #require(URL(string: "https://example.com/old-revision/model.gguf"))
        resumeStore.persist(Data("partial bytes".utf8), for: previousRevision)

        // Repinning the model revision must not leave a sidecar that fails
        // every future resume attempt.
        #expect(resumeStore.load(for: fixture.sourceURL) == nil)
        #expect(!FileManager.default.fileExists(atPath: fixture.resumeDataURL.path))
    }
}

/// Thread-safe collector for progress values captured in `@Sendable` closures.
final class ProgressCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Double] = []

    var value: [Double] {
        lock.withLock { storage }
    }

    func append(_ element: Double) {
        lock.withLock { storage.append(element) }
    }
}
