import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSharedURLImportService Tests", .serialized)
@MainActor
struct LiveSharedURLImportServiceTests {
    let suiteName: String
    let defaults: UserDefaults
    let queue: SharedURLQueue
    let sut: LiveSharedURLImportService

    init() throws {
        suiteName = "test.group.livesharedurl.\(UUID().uuidString)"
        let store = try #require(UserDefaults(suiteName: suiteName))
        store.removePersistentDomain(forName: suiteName)
        defaults = store
        queue = SharedURLQueue(defaults: store)
        sut = LiveSharedURLImportService(queue: queue)
    }

    // MARK: - hasPendingItems

    @Test("hasPendingItems is false on empty queue")
    func hasPendingItemsEmpty() {
        #expect(sut.hasPendingItems == false)
    }

    @Test("hasPendingItems becomes true after enqueue")
    func hasPendingItemsAfterEnqueue() {
        queue.enqueue(SharedURLItem(url: "https://example.com/a", sharedAt: Date()))

        #expect(sut.hasPendingItems == true)
    }

    // MARK: - processPendingItems

    @Test("processPendingItems publishes a single queued URL")
    func processPublishesSingleURL() async throws {
        let expected = try #require(URL(string: "https://example.com/single"))
        queue.enqueue(SharedURLItem(url: expected.absoluteString, sharedAt: Date()))

        var cancellables = Set<AnyCancellable>()
        var received: [URL] = []
        sut.pendingURLPublisher
            .sink { url in received.append(url) }
            .store(in: &cancellables)

        sut.processPendingItems()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(received == [expected])
        #expect(sut.hasPendingItems == false)
    }

    @Test("processPendingItems publishes multiple queued URLs in FIFO order")
    func processPublishesMultipleURLs() async throws {
        let first = try #require(URL(string: "https://example.com/first"))
        let second = try #require(URL(string: "https://example.com/second"))
        queue.enqueue(SharedURLItem(url: first.absoluteString, sharedAt: Date()))
        queue.enqueue(SharedURLItem(url: second.absoluteString, sharedAt: Date().addingTimeInterval(1)))

        var cancellables = Set<AnyCancellable>()
        var received: [URL] = []
        sut.pendingURLPublisher
            .sink { url in received.append(url) }
            .store(in: &cancellables)

        sut.processPendingItems()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(received == [first, second])
        #expect(sut.hasPendingItems == false)
    }

    @Test("processPendingItems drops malformed URL strings without publishing")
    func processDropsMalformedURL() async throws {
        // URL(string:) returns nil for empty strings, which is the most
        // reliable invariant across iOS versions for "malformed input".
        #expect(URL(string: "") == nil)

        let valid = try #require(URL(string: "https://example.com/valid"))
        queue.enqueue(SharedURLItem(url: "", sharedAt: Date()))
        queue.enqueue(SharedURLItem(url: valid.absoluteString, sharedAt: Date().addingTimeInterval(1)))

        var cancellables = Set<AnyCancellable>()
        var received: [URL] = []
        sut.pendingURLPublisher
            .sink { url in received.append(url) }
            .store(in: &cancellables)

        sut.processPendingItems()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(received == [valid])
        #expect(sut.hasPendingItems == false)
    }

    @Test("processPendingItems on empty queue does not publish")
    func processOnEmptyDoesNotPublish() async throws {
        var cancellables = Set<AnyCancellable>()
        var received: [URL] = []
        sut.pendingURLPublisher
            .sink { url in received.append(url) }
            .store(in: &cancellables)

        sut.processPendingItems()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(received.isEmpty)
        #expect(sut.hasPendingItems == false)
    }
}
