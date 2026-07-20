import Foundation
@testable import Pulse
import Testing

@Suite("SharedURLQueue Tests", .serialized)
struct SharedURLQueueTests {
    let suiteName: String
    let defaults: UserDefaults
    var sut: SharedURLQueue

    init() throws {
        suiteName = "test.group.sharedurlqueue.\(UUID().uuidString)"
        let store = try #require(UserDefaults(suiteName: suiteName))
        store.removePersistentDomain(forName: suiteName)
        defaults = store
        sut = SharedURLQueue(defaults: store)
    }

    // MARK: - Codable round-trip

    @Test("SharedURLItem round-trips through JSON")
    func sharedURLItemRoundTrip() throws {
        let original = SharedURLItem(
            url: "https://example.com/article",
            sharedAt: Date(timeIntervalSince1970: 1_700_000_000),
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SharedURLItem.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Enqueue / peek

    @Test("Enqueue then peekAll returns the item")
    func enqueueThenPeek() {
        let item = SharedURLItem(url: "https://example.com/a", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == true)
        #expect(sut.peekAll() == [item])
    }

    @Test("Enqueue twice preserves FIFO order in drain")
    func enqueueTwiceFIFODrain() {
        let first = SharedURLItem(url: "https://example.com/first", sharedAt: Date())
        let second = SharedURLItem(url: "https://example.com/second", sharedAt: Date().addingTimeInterval(1))
        sut.enqueue(first)
        sut.enqueue(second)

        let drained = sut.drain()

        #expect(drained == [first, second])
        #expect(sut.peekAll().isEmpty)
    }

    // MARK: - Dequeue

    @Test("Dequeue on empty queue returns nil")
    func dequeueEmptyReturnsNil() {
        #expect(sut.dequeue() == nil)
    }

    @Test("Dequeue removes the head item")
    func dequeueRemovesHead() {
        let head = SharedURLItem(url: "https://example.com/head", sharedAt: Date())
        let tail = SharedURLItem(url: "https://example.com/tail", sharedAt: Date().addingTimeInterval(1))
        sut.enqueue(head)
        sut.enqueue(tail)

        let popped = sut.dequeue()

        #expect(popped == head)
        #expect(sut.peekAll() == [tail])
    }

    // MARK: - Clear

    @Test("Clear empties the queue")
    func clearEmptiesQueue() {
        sut.enqueue(SharedURLItem(url: "https://example.com/a", sharedAt: Date()))
        sut.enqueue(SharedURLItem(url: "https://example.com/b", sharedAt: Date()))

        sut.clear()

        #expect(sut.peekAll().isEmpty)
        #expect(sut.hasNoStoredKey(in: defaults) == true)
    }

    // MARK: - Corruption resilience

    @Test("Corrupted UserDefaults payload is treated as empty queue")
    func corruptedPayloadHandled() {
        defaults.set(Data(), forKey: SharedURLQueue.queueKey)

        #expect(sut.peekAll().isEmpty)

        // The queue should still accept new items after a corrupted read.
        let item = SharedURLItem(url: "https://example.com/recover", sharedAt: Date())
        let success = sut.enqueue(item)

        #expect(success == true)
        #expect(sut.peekAll() == [item])
    }

    // MARK: - Missing defaults safety

    @Test("Queue with nil defaults degrades gracefully")
    func nilDefaultsDegradesGracefully() {
        let nilQueue = SharedURLQueue(defaults: nil)

        #expect(nilQueue.enqueue(SharedURLItem(url: "https://example.com", sharedAt: Date())) == false)
        #expect(nilQueue.peekAll().isEmpty)
        #expect(nilQueue.dequeue() == nil)
        #expect(nilQueue.drain().isEmpty)
        nilQueue.clear()
    }

    // MARK: - Size cap

    @Test("Enqueue beyond maxQueueSize evicts oldest entries (FIFO)")
    func enqueueEvictsOldestWhenOverCapacity() {
        // Push exactly maxQueueSize + 5 items so we can verify the first 5 are dropped.
        let overflow = 5
        let total = SharedURLQueue.maxQueueSize + overflow
        for index in 0 ..< total {
            sut.enqueue(SharedURLItem(
                url: "https://example.com/\(index)",
                sharedAt: Date(timeIntervalSince1970: TimeInterval(index)),
            ))
        }

        let snapshot = sut.peekAll()
        #expect(snapshot.count == SharedURLQueue.maxQueueSize)
        // The first `overflow` items should be evicted, so the new head is item #5.
        #expect(snapshot.first?.url == "https://example.com/\(overflow)")
        #expect(snapshot.last?.url == "https://example.com/\(total - 1)")
    }

    @Test("Read side re-caps a directly-written oversized payload (symmetric with enqueue)")
    func readSideCapsOversizedPayload() throws {
        // Simulate a tampered / first-party-bug write that bypasses `enqueue`'s
        // cap by writing an oversized array straight to the App Group key.
        let overflow = 10
        let total = SharedURLQueue.maxQueueSize + overflow
        let items = (0 ..< total).map { index in
            SharedURLItem(
                url: "https://example.com/\(index)",
                sharedAt: Date(timeIntervalSince1970: TimeInterval(index)),
            )
        }
        let encoded = try JSONEncoder().encode(items)
        defaults.set(encoded, forKey: SharedURLQueue.queueKey)

        // Both read paths must be bounded, keeping the newest items.
        #expect(sut.peekAll().count == SharedURLQueue.maxQueueSize)
        #expect(sut.peekAll().last?.url == "https://example.com/\(total - 1)")
        #expect(sut.drain().count == SharedURLQueue.maxQueueSize)
    }

    // MARK: - Scheme / length validation

    @Test("Enqueue rejects javascript: scheme")
    func enqueueRejectsJavascriptScheme() {
        let item = SharedURLItem(url: "javascript:alert(1)", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == false)
        #expect(sut.peekAll().isEmpty)
    }

    @Test("Enqueue rejects data: scheme")
    func enqueueRejectsDataScheme() {
        let item = SharedURLItem(url: "data:text/html,<script>alert(1)</script>", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == false)
        #expect(sut.peekAll().isEmpty)
    }

    @Test("Enqueue rejects file: scheme")
    func enqueueRejectsFileScheme() {
        let item = SharedURLItem(url: "file:///etc/passwd", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == false)
        #expect(sut.peekAll().isEmpty)
    }

    @Test("Enqueue rejects custom scheme")
    func enqueueRejectsCustomScheme() {
        let item = SharedURLItem(url: "pulse://settings", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == false)
        #expect(sut.peekAll().isEmpty)
    }

    @Test("Enqueue rejects URL longer than maxURLLength")
    func enqueueRejectsOversizedURL() {
        let longPath = String(repeating: "a", count: SharedURLQueue.maxURLLength + 1)
        let item = SharedURLItem(url: "https://example.com/\(longPath)", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == false)
        #expect(sut.peekAll().isEmpty)
    }

    @Test("Enqueue rejects empty URL string")
    func enqueueRejectsEmptyURL() {
        let item = SharedURLItem(url: "", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == false)
        #expect(sut.peekAll().isEmpty)
    }

    @Test("Enqueue accepts http URL")
    func enqueueAcceptsHTTP() {
        let item = SharedURLItem(url: "http://example.com/article", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == true)
        #expect(sut.peekAll().count == 1)
    }

    @Test("isAcceptable static helper matches enqueue rules")
    func isAcceptableMatchesEnqueue() {
        #expect(SharedURLQueue.isAcceptable(urlString: "https://example.com") == true)
        #expect(SharedURLQueue.isAcceptable(urlString: "http://example.com") == true)
        #expect(SharedURLQueue.isAcceptable(urlString: "javascript:alert(1)") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "data:,foo") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "file:///etc") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "pulse://x") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "") == false)
        let oversized = "https://example.com/" + String(repeating: "a", count: SharedURLQueue.maxURLLength)
        #expect(SharedURLQueue.isAcceptable(urlString: oversized) == false)
    }

    // MARK: - Path-traversal rejection

    @Test("Enqueue rejects URL with .. in path")
    func enqueueRejectsPathTraversal() {
        let item = SharedURLItem(url: "https://example.com/../../etc/passwd", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == false)
        #expect(sut.peekAll().isEmpty)
    }

    @Test("isAcceptable rejects .. at various path positions")
    func isAcceptableRejectsPathTraversalVariants() {
        #expect(SharedURLQueue.isAcceptable(urlString: "https://example.com/foo/../../bar") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "https://example.com/./../secret") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "https://example.com/normal/path") == true)
    }

    // MARK: - Control character rejection

    @Test("Enqueue rejects URL with control characters")
    func enqueueRejectsControlChars() {
        let item = SharedURLItem(url: "https://example.com/\u{00}\u{01}\u{7F}test", sharedAt: Date())

        let success = sut.enqueue(item)

        #expect(success == false)
        #expect(sut.peekAll().isEmpty)
    }

    @Test("isAcceptable rejects URLs with control characters")
    func isAcceptableRejectsControlChars() {
        #expect(SharedURLQueue.isAcceptable(urlString: "https://example.com/\u{00}") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "https://example.com/\u{01}") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "https://example.com/\u{7F}") == false)
        #expect(SharedURLQueue.isAcceptable(urlString: "https://example.com/normal") == true)
    }
}

private extension SharedURLQueue {
    /// Returns `true` if the underlying defaults no longer hold the queue key.
    /// Helper kept private to the test target via the file-private extension.
    func hasNoStoredKey(in defaults: UserDefaults) -> Bool {
        defaults.data(forKey: SharedURLQueue.queueKey) == nil
    }
}
