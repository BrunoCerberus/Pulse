import CryptoKit
import Foundation
@testable import Pulse
import Testing

/// Serves canned responses so the download path can be exercised without a network.
final class StubModelDownloadProtocol: URLProtocol, @unchecked Sendable {
    struct Response {
        var statusCode: Int
        var body: Data
        var error: URLError?
    }

    private nonisolated(unsafe) static var response = Response(statusCode: 200, body: Data(), error: nil)
    private nonisolated(unsafe) static var requestedURLs: [URL] = []
    private static let lock = NSLock()

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
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
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
