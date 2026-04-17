import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("CloudSyncDomainInteractor Tests")
@MainActor
struct CloudSyncDomainInteractorTests {
    let mockCloudSyncService: MockCloudSyncService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let notificationCenter: NotificationCenter
    let sut: CloudSyncDomainInteractor

    init() {
        mockCloudSyncService = MockCloudSyncService(accountStatus: .couldNotDetermine, syncState: .idle)
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()
        notificationCenter = NotificationCenter()

        serviceLocator.register(CloudSyncService.self, instance: mockCloudSyncService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

        sut = CloudSyncDomainInteractor(
            serviceLocator: serviceLocator,
            notificationCenter: notificationCenter
        )
    }

    // MARK: - Initial State

    @Test("Initial state matches .initial")
    func initialState() async throws {
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        let state = sut.currentState
        #expect(state.accountStatus == .couldNotDetermine)
        #expect(state.syncState == .idle)
        #expect(state.lastSyncedAt == nil)
        #expect(state.isAvailable == false)
    }

    // MARK: - Dispatch -> Service delegation

    @Test("Dispatch startObserving forwards to service")
    func dispatchStartObserving() {
        sut.dispatch(action: .startObserving)
        #expect(mockCloudSyncService.startObservingCallCount == 1)
        #expect(mockCloudSyncService.isObserving == true)
    }

    @Test("Dispatch stopObserving forwards to service")
    func dispatchStopObserving() {
        sut.dispatch(action: .stopObserving)
        #expect(mockCloudSyncService.stopObservingCallCount == 1)
    }

    @Test("Dispatch refreshAccountStatus forwards to service")
    func dispatchRefreshAccountStatus() {
        sut.dispatch(action: .refreshAccountStatus)
        #expect(mockCloudSyncService.refreshAccountStatusCallCount == 1)
    }

    // MARK: - Sync State Transitions

    @Test("Syncing emission updates state and logs analytics")
    func syncingTransitionLogsAnalytics() async throws {
        mockCloudSyncService.emit(syncState: .syncing)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.syncState == .syncing)
        let hasStarted = mockAnalyticsService.loggedEvents.contains { $0.name == "cloud_sync_started" }
        #expect(hasStarted)
    }

    @Test("Succeeded emission updates lastSyncedAt, logs analytics, posts notification")
    func succeededTransitionPostsNotification() async throws {
        var cancellables = Set<AnyCancellable>()
        var received = false
        notificationCenter.publisher(for: .cloudSyncDidComplete)
            .sink { _ in received = true }
            .store(in: &cancellables)

        let syncDate = Date(timeIntervalSince1970: 1_700_000_000)
        mockCloudSyncService.emit(syncState: .succeeded(syncDate))
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.lastSyncedAt == syncDate)
        let succeededEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "cloud_sync_succeeded" }
        #expect(succeededEvents.count == 1)
        #expect(received)
    }

    @Test("Failed emission logs analytics + records error, does NOT post completion")
    func failedTransitionLogsError() async throws {
        var cancellables = Set<AnyCancellable>()
        var received = false
        notificationCenter.publisher(for: .cloudSyncDidComplete)
            .sink { _ in received = true }
            .store(in: &cancellables)

        mockCloudSyncService.emit(syncState: .failed("boom"))
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let failedEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "cloud_sync_failed" }
        #expect(failedEvents.count == 1)
        #expect(mockAnalyticsService.recordedErrors.count == 1)
        #expect(received == false)
    }

    @Test("Idle emission does not log analytics or post notification")
    func idleTransitionIsNoop() async throws {
        // Force a non-idle state first so the idle emission actually flips.
        mockCloudSyncService.emit(syncState: .syncing)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        mockAnalyticsService.reset()

        mockCloudSyncService.emit(syncState: .idle)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockAnalyticsService.loggedEvents.isEmpty)
        #expect(sut.currentState.syncState == .idle)
    }

    // MARK: - Account Status Transitions

    @Test("Account status update propagates into state")
    func accountStatusUpdatesState() async throws {
        mockCloudSyncService.emit(accountStatus: .available)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.accountStatus == .available)
        #expect(sut.currentState.isAvailable == true)
    }

    @Test("Account status downgrade to noAccount logs analytics")
    func accountUnavailableLogsAnalytics() async throws {
        // Start from .available to exercise the "downgrade" path.
        mockCloudSyncService.emit(accountStatus: .available)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        mockAnalyticsService.reset()

        mockCloudSyncService.emit(accountStatus: .noAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let unavailableEvents = mockAnalyticsService.loggedEvents.filter {
            $0.name == "cloud_sync_account_unavailable"
        }
        #expect(unavailableEvents.count == 1)
        #expect(sut.currentState.isAvailable == false)
    }

    @Test("Account status unchanged emissions are deduplicated")
    func duplicateAccountStatusDoesNotSpamAnalytics() async throws {
        mockCloudSyncService.emit(accountStatus: .noAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        let firstCount = mockAnalyticsService.loggedEvents.count

        mockCloudSyncService.emit(accountStatus: .noAccount)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        let secondCount = mockAnalyticsService.loggedEvents.count

        #expect(firstCount == secondCount)
    }
}
