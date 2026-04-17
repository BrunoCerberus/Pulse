import Combine
import CoreData
import Foundation
@testable import Pulse
import Testing

@Suite("LiveCloudSyncService Tests")
struct LiveCloudSyncServiceTests {
    // MARK: - Initial State

    @Test("Initial state defaults to not available")
    func initialState() {
        let sut = LiveCloudSyncService(notificationCenter: NotificationCenter())
        #expect(sut.isAvailable == false)
    }

    // MARK: - Event Handling

    @Test("Event without endDate maps to syncing")
    func eventStartMapsToSyncing() async throws {
        let sut = LiveCloudSyncService(notificationCenter: NotificationCenter())
        sut.applyEvent(endDate: nil, error: nil, succeeded: false)

        let publisher = sut.syncStatePublisher.setFailureType(to: Error.self).eraseToAnyPublisher()
        let latest = try await awaitPublisher(publisher)
        #expect(latest == .syncing)
    }

    @Test("Event with endDate and success maps to succeeded")
    func eventEndMapsToSucceeded() async throws {
        let sut = LiveCloudSyncService(notificationCenter: NotificationCenter())
        let endDate = Date(timeIntervalSince1970: 1_700_000_000)
        sut.applyEvent(endDate: endDate, error: nil, succeeded: true)

        let publisher = sut.syncStatePublisher.setFailureType(to: Error.self).eraseToAnyPublisher()
        let latest = try await awaitPublisher(publisher)
        if case let .succeeded(date) = latest {
            #expect(date == endDate)
        } else {
            Issue.record("Expected .succeeded, got \(latest)")
        }
    }

    @Test("Event with error maps to failed")
    func eventErrorMapsToFailed() async throws {
        struct TestError: LocalizedError {
            var errorDescription: String? {
                "boom"
            }
        }
        let sut = LiveCloudSyncService(notificationCenter: NotificationCenter())
        sut.applyEvent(endDate: Date(), error: TestError(), succeeded: false)

        let publisher = sut.syncStatePublisher.setFailureType(to: Error.self).eraseToAnyPublisher()
        let latest = try await awaitPublisher(publisher)
        if case let .failed(message) = latest {
            #expect(message == "boom")
        } else {
            Issue.record("Expected .failed, got \(latest)")
        }
    }

    @Test("Event without success flag and no error still maps to failed")
    func eventEndWithoutSuccessMapsToFailed() async throws {
        let sut = LiveCloudSyncService(notificationCenter: NotificationCenter())
        sut.applyEvent(endDate: Date(), error: nil, succeeded: false)

        let publisher = sut.syncStatePublisher.setFailureType(to: Error.self).eraseToAnyPublisher()
        let latest = try await awaitPublisher(publisher)
        if case .failed = latest {
            // ok
        } else {
            Issue.record("Expected .failed, got \(latest)")
        }
    }

    // MARK: - Observation Lifecycle

    @Test("startObserving is idempotent")
    func startObservingIdempotent() {
        let sut = LiveCloudSyncService(notificationCenter: NotificationCenter())
        sut.startObserving()
        sut.startObserving()
        sut.stopObserving()
        // Passing pre-existing idempotency guard without crashing is the
        // contract we want to assert.
    }

    @Test("stopObserving drops notification subscriptions")
    func stopObservingDropsSubscriptions() async throws {
        let notificationCenter = NotificationCenter()
        let sut = LiveCloudSyncService(notificationCenter: notificationCenter)
        sut.startObserving()
        sut.stopObserving()

        // Posting a new event after stopObserving should NOT change the
        // sync state. We verify by posting then asserting state stays idle.
        notificationCenter.post(
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            userInfo: [:]
        )
        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        var cancellables = Set<AnyCancellable>()
        var latest: CloudSyncState = .idle
        sut.syncStatePublisher.sink { latest = $0 }.store(in: &cancellables)
        #expect(latest == .idle)
    }

    // MARK: - Account Status Mapping

    @Test("Account status mapping covers all CKAccountStatus cases")
    func accountStatusMapping() {
        #expect(LiveCloudSyncService.map(ckAccountStatus: .available) == .available)
        #expect(LiveCloudSyncService.map(ckAccountStatus: .noAccount) == .noAccount)
        #expect(LiveCloudSyncService.map(ckAccountStatus: .restricted) == .restricted)
        #expect(LiveCloudSyncService.map(ckAccountStatus: .temporarilyUnavailable) == .temporarilyUnavailable)
        #expect(LiveCloudSyncService.map(ckAccountStatus: .couldNotDetermine) == .couldNotDetermine)
    }
}
