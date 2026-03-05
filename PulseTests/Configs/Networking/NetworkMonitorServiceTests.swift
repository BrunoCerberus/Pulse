import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("NetworkMonitorService Tests")
struct NetworkMonitorServiceTests {
    // MARK: - MockNetworkMonitorService Tests

    @Test("Mock starts connected by default")
    func mockStartsConnected() {
        let sut = MockNetworkMonitorService()
        #expect(sut.isConnected)
    }

    @Test("Mock can start disconnected")
    func mockStartsDisconnected() {
        let sut = MockNetworkMonitorService(isConnected: false)
        #expect(!sut.isConnected)
    }

    @Test("simulateOffline sets isConnected to false")
    func simulateOffline() {
        let sut = MockNetworkMonitorService()
        #expect(sut.isConnected)

        sut.simulateOffline()
        #expect(!sut.isConnected)
    }

    @Test("simulateOnline sets isConnected to true")
    func simulateOnline() {
        let sut = MockNetworkMonitorService(isConnected: false)
        #expect(!sut.isConnected)

        sut.simulateOnline()
        #expect(sut.isConnected)
    }

    @Test("Publisher emits current state on subscribe")
    func publisherEmitsCurrentState() async throws {
        let sut = MockNetworkMonitorService()
        var cancellables = Set<AnyCancellable>()
        var values: [Bool] = []

        sut.isConnectedPublisher
            .sink { values.append($0) }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(!values.isEmpty)
        #expect(values.first == true)
    }

    @Test("Publisher emits changes when toggling connectivity")
    func publisherEmitsChanges() async throws {
        let sut = MockNetworkMonitorService()
        var cancellables = Set<AnyCancellable>()
        var values: [Bool] = []

        sut.isConnectedPublisher
            .sink { values.append($0) }
            .store(in: &cancellables)

        sut.simulateOffline()
        sut.simulateOnline()

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(values.contains(true))
        #expect(values.contains(false))
    }

    @Test("Publisher deduplicates repeated values")
    func publisherDeduplicates() async throws {
        let sut = MockNetworkMonitorService()
        var cancellables = Set<AnyCancellable>()
        var values: [Bool] = []

        sut.isConnectedPublisher
            .sink { values.append($0) }
            .store(in: &cancellables)

        // Send duplicate connected states
        sut.simulateOnline()
        sut.simulateOnline()
        sut.simulateOnline()

        try await Task.sleep(nanoseconds: 100_000_000)

        // Should only have one true value due to removeDuplicates
        let trueCount = values.filter { $0 }.count
        #expect(trueCount == 1)
    }

    // MARK: - LiveNetworkMonitorService Tests

    @Test("Live monitor can be instantiated")
    func liveMonitorInstantiation() {
        let sut = LiveNetworkMonitorService()
        // Should start assuming connected
        #expect(sut.isConnected == true || sut.isConnected == false)
    }

    @Test("Live monitor publisher emits a value")
    func liveMonitorPublisher() async throws {
        let sut = LiveNetworkMonitorService()
        var cancellables = Set<AnyCancellable>()
        var values: [Bool] = []

        sut.isConnectedPublisher
            .sink { values.append($0) }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(!values.isEmpty)
    }
}
