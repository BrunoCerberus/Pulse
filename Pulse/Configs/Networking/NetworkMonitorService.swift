import Combine
import Foundation
import Network

// MARK: - Protocol

/// Protocol for monitoring network connectivity status.
protocol NetworkMonitorService: AnyObject {
    /// Whether the device currently has network connectivity.
    var isConnected: Bool { get }

    /// Publisher that emits connectivity changes (deduplicated).
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
}

// MARK: - Live Implementation

/// Live implementation using NWPathMonitor on a dedicated queue.
final class LiveNetworkMonitorService: NetworkMonitorService {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.pulse.networkmonitor")
    private let subject = CurrentValueSubject<Bool, Never>(true)

    var isConnected: Bool {
        subject.value
    }

    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        subject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.subject.send(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Mock Implementation

/// Mock implementation for testing and previews.
final class MockNetworkMonitorService: NetworkMonitorService {
    private let subject: CurrentValueSubject<Bool, Never>

    var isConnected: Bool {
        subject.value
    }

    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        subject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    init(isConnected: Bool = true) {
        subject = CurrentValueSubject(isConnected)
    }

    func simulateOffline() {
        subject.send(false)
    }

    func simulateOnline() {
        subject.send(true)
    }
}
