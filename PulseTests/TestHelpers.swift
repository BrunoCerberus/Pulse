import Combine
import EntropyCore
import Foundation
@testable import Pulse

// MARK: - Async Testing Helpers

// Shared test utilities for async operations and common test setup.
// This file provides:
// - Helper for async state verification with proper waiting
// - Shared ServiceLocator factory for consistent mock setup
// - Common test constants and utilities
//
// Note: Tests that modify singleton state (AuthenticationManager) must run serially.

/// Wait duration constants for Combine pipeline propagation
enum TestWaitDuration {
    /// Short wait for simple state updates (100ms)
    static let short: UInt64 = 100_000_000

    /// Standard wait for most Combine operations (200ms)
    static let standard: UInt64 = 200_000_000

    /// Long wait for complex async chains (500ms)
    static let long: UInt64 = 500_000_000
}

/// Async helper to wait for Combine publisher state changes.
/// Uses a shorter default timeout than raw Task.sleep for faster tests.
func waitForStateUpdate(duration: UInt64 = TestWaitDuration.standard) async throws {
    try await Task.sleep(nanoseconds: duration)
}

/// Waits for a condition to become true within a timeout.
/// Returns true if condition was met, false if timeout expired.
///
/// - Parameters:
///   - timeout: Maximum time to wait in nanoseconds (default 500ms)
///   - interval: Check interval in nanoseconds (default 10ms)
///   - condition: Closure that returns true when desired state is reached
/// - Returns: True if condition was met within timeout
@MainActor
func waitForCondition(
    timeout: UInt64 = 500_000_000,
    interval: UInt64 = 10_000_000,
    condition: @escaping @MainActor () -> Bool
) async -> Bool {
    let deadline = DispatchTime.now().uptimeNanoseconds + timeout
    while DispatchTime.now().uptimeNanoseconds < deadline {
        if condition() {
            return true
        }
        try? await Task.sleep(nanoseconds: interval)
    }
    return condition()
}

func waitForCondition(
    timeout: UInt64 = 500_000_000,
    interval: UInt64 = 10_000_000,
    condition: sending @escaping () -> Bool
) async -> Bool {
    let deadline = DispatchTime.now().uptimeNanoseconds + timeout
    while DispatchTime.now().uptimeNanoseconds < deadline {
        if condition() {
            return true
        }
        try? await Task.sleep(nanoseconds: interval)
    }
    return condition()
}

// MARK: - Publisher Awaiting

enum PublisherError: Error {
    case finishedWithoutValue
}

/// Bridges a Combine publisher to async/await for test assertions.
/// Uses `.first()` to take the first emitted value. If the publisher
/// completes without emitting, throws `PublisherError.finishedWithoutValue`.
func awaitPublisher<T>(_ publisher: AnyPublisher<T, Error>) async throws -> T {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
        nonisolated(unsafe) let continuation = continuation
        var resumed = false
        var cancellable: AnyCancellable?
        cancellable = publisher
            .first()
            .sink(
                receiveCompletion: { completion in
                    guard !resumed else {
                        cancellable?.cancel()
                        return
                    }
                    if case let .failure(error) = completion {
                        resumed = true
                        continuation.resume(throwing: error)
                    } else {
                        // .finished without a value
                        resumed = true
                        continuation.resume(throwing: PublisherError.finishedWithoutValue)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    guard !resumed else { return }
                    resumed = true
                    nonisolated(unsafe) let value = value
                    continuation.resume(returning: value)
                }
            )
    }
}

// MARK: - ServiceLocator Factory

/// Container for mock services returned by TestServiceLocatorFactory.
struct TestMockServices {
    let serviceLocator: ServiceLocator
    let newsService: MockNewsService
    let storageService: MockStorageService
}

/// Factory for creating pre-configured ServiceLocators with mock services.
/// Use these for consistent test setup across all test suites.
enum TestServiceLocatorFactory {
    /// Creates a ServiceLocator with all mock services registered.
    /// Use this as the base for most test setups.
    static func createFullyMocked() -> ServiceLocator {
        let serviceLocator = ServiceLocator()

        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())
        serviceLocator.register(LLMService.self, instance: MockLLMService())
        serviceLocator.register(SummarizationService.self, instance: MockSummarizationService())
        serviceLocator.register(FeedService.self, instance: MockFeedService())
        serviceLocator.register(OnboardingService.self, instance: MockOnboardingService())
        serviceLocator.register(TextToSpeechService.self, instance: MockTextToSpeechService())
        serviceLocator.register(SharedURLImportService.self, instance: MockSharedURLImportService())

        return serviceLocator
    }

    /// Creates a ServiceLocator with news and storage mock services.
    /// Returns the ServiceLocator and mock instances for test manipulation.
    static func createWithCustomizableMocks() -> TestMockServices {
        let serviceLocator = ServiceLocator()

        let newsService = MockNewsService()
        let storageService = MockStorageService()

        serviceLocator.register(NewsService.self, instance: newsService)
        serviceLocator.register(StorageService.self, instance: storageService)
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())
        serviceLocator.register(LLMService.self, instance: MockLLMService())
        serviceLocator.register(SummarizationService.self, instance: MockSummarizationService())
        serviceLocator.register(FeedService.self, instance: MockFeedService())
        serviceLocator.register(OnboardingService.self, instance: MockOnboardingService())
        serviceLocator.register(TextToSpeechService.self, instance: MockTextToSpeechService())

        return TestMockServices(
            serviceLocator: serviceLocator,
            newsService: newsService,
            storageService: storageService
        )
    }
}

// MARK: - Mock Service Extensions

extension MockStorageService {
    /// Convenience property for setting mocked bookmarked articles
    var mockBookmarkedArticles: [Article] {
        get { bookmarkedArticles }
        set { bookmarkedArticles = newValue }
    }

    /// Convenience property for setting mocked user preferences
    var mockUserPreferences: UserPreferences? {
        get { userPreferences }
        set { userPreferences = newValue }
    }
}
