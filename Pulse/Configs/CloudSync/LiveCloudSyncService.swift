import CloudKit
import Combine
import CoreData
import EntropyCore
import Foundation

/// Live CloudKit sync observer.
///
/// Bridges `NSPersistentCloudKitContainer.eventChangedNotification` (which
/// SwiftData's CloudKit-backed `ModelContainer` emits under the hood) and
/// CloudKit's `CKAccountChanged` notification into two `CurrentValueSubject`s
/// that the rest of the app consumes as Combine publishers.
///
/// The service does not itself perform syncing — SwiftData owns that — it
/// only reports what's happening so the domain layer can log analytics and
/// fan out a `.cloudSyncDidComplete` notification that feature interactors
/// subscribe to.
final class LiveCloudSyncService: CloudSyncService, @unchecked Sendable {
    private let containerIdentifier: String
    private let notificationCenter: NotificationCenter
    private let accountStatusSubject = CurrentValueSubject<CloudSyncAccountStatus, Never>(.couldNotDetermine)
    private let syncStateSubject = CurrentValueSubject<CloudSyncState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()
    private var isObserving = false

    var accountStatusPublisher: AnyPublisher<CloudSyncAccountStatus, Never> {
        accountStatusSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<CloudSyncState, Never> {
        syncStateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var isAvailable: Bool {
        accountStatusSubject.value == .available
    }

    /// - Parameters:
    ///   - containerIdentifier: iCloud container ID matching the entitlement.
    ///   - notificationCenter: Injected for testability.
    init(
        containerIdentifier: String = "iCloud.com.bruno.Pulse-News",
        notificationCenter: NotificationCenter = .default
    ) {
        self.containerIdentifier = containerIdentifier
        self.notificationCenter = notificationCenter
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        notificationCenter.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleContainerEvent(notification)
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAccountStatus()
            }
            .store(in: &cancellables)

        refreshAccountStatus()
    }

    func stopObserving() {
        cancellables.removeAll()
        isObserving = false
    }

    func refreshAccountStatus() {
        let container = CKContainer(identifier: containerIdentifier)
        container.accountStatus { [weak self] status, error in
            guard let self else { return }
            if let error {
                Logger.shared.service("CloudKit account status error: \(error)", level: .warning)
            }
            let mapped = Self.map(ckAccountStatus: status)
            DispatchQueue.main.async {
                self.accountStatusSubject.send(mapped)
            }
        }
    }

    // MARK: - Notification Parsing

    /// Dispatched when `NSPersistentCloudKitContainer` posts an event change.
    /// Extracts the relevant fields and forwards them to `applyEvent`.
    func handleContainerEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
            as? NSPersistentCloudKitContainer.Event
        else {
            return
        }

        applyEvent(endDate: event.endDate, error: event.error, succeeded: event.succeeded)
    }

    /// Translates the relevant CloudKit event fields into a `CloudSyncState`.
    /// Extracted so unit tests can drive the state machine deterministically
    /// without fabricating an `NSPersistentCloudKitContainer.Event` instance
    /// (that class cannot be subclassed or constructed from outside Core Data).
    func applyEvent(endDate: Date?, error: Error?, succeeded: Bool) {
        if endDate == nil {
            syncStateSubject.send(.syncing)
            return
        }

        if let error {
            syncStateSubject.send(.failed(error.localizedDescription))
        } else if succeeded {
            syncStateSubject.send(.succeeded(endDate ?? Date()))
        } else {
            syncStateSubject.send(.failed("CloudKit sync finished without success"))
        }
    }

    static func map(ckAccountStatus status: CKAccountStatus) -> CloudSyncAccountStatus {
        switch status {
        case .available:
            return .available
        case .noAccount:
            return .noAccount
        case .restricted:
            return .restricted
        case .temporarilyUnavailable:
            return .temporarilyUnavailable
        case .couldNotDetermine:
            return .couldNotDetermine
        @unknown default:
            return .couldNotDetermine
        }
    }
}
