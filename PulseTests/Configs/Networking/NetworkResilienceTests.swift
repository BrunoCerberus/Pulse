import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("NetworkResilience Tests")
struct NetworkResilienceTests {
    // Tests use DispatchQueue.main as the scheduler to avoid ordering issues
    // with synchronous mock publishers. Production uses .global() by default.

    // MARK: - Success on first attempt

    @Test("Succeeds immediately without retry")
    func successNoRetry() async throws {
        var callCount = 0
        let publisher = Deferred {
            Future<String, Error> { promise in
                callCount += 1
                promise(.success("ok"))
            }
        }
        .withNetworkResilience(maxRetries: 2, baseDelay: 0.01, timeout: 5.0, scheduler: DispatchQueue.main)

        let result = try await awaitPublisher(publisher)
        #expect(result == "ok")
        #expect(callCount == 1)
    }

    // MARK: - Retry on failure then succeed

    @Test("Retries on failure and succeeds")
    func retryThenSucceed() async throws {
        var callCount = 0
        let publisher = Deferred {
            Future<String, Error> { promise in
                callCount += 1
                if callCount < 3 {
                    promise(.failure(URLError(.networkConnectionLost)))
                } else {
                    promise(.success("recovered"))
                }
            }
        }
        .withNetworkResilience(maxRetries: 2, baseDelay: 0.01, timeout: 5.0, scheduler: DispatchQueue.main)

        let result = try await awaitPublisher(publisher)
        #expect(result == "recovered")
        #expect(callCount == 3)
    }

    // MARK: - Exhausts retries

    @Test("Fails after exhausting retries")
    func exhaustRetries() async throws {
        var callCount = 0
        let publisher = Deferred {
            Future<String, Error> { promise in
                callCount += 1
                promise(.failure(URLError(.notConnectedToInternet)))
            }
        }
        .withNetworkResilience(maxRetries: 2, baseDelay: 0.01, timeout: 5.0, scheduler: DispatchQueue.main)

        do {
            _ = try await awaitPublisher(publisher)
            Issue.record("Expected failure")
        } catch {
            #expect(callCount == 3) // 1 initial + 2 retries
        }
    }

    // MARK: - Zero retries

    @Test("Zero retries fails immediately")
    func zeroRetries() async throws {
        var callCount = 0
        let publisher = Deferred {
            Future<String, Error> { promise in
                callCount += 1
                promise(.failure(URLError(.badServerResponse)))
            }
        }
        .withNetworkResilience(maxRetries: 0, baseDelay: 0.01, timeout: 5.0, scheduler: DispatchQueue.main)

        do {
            _ = try await awaitPublisher(publisher)
            Issue.record("Expected failure")
        } catch {
            #expect(callCount == 1)
        }
    }

    // MARK: - Timeout

    @Test("Times out slow publisher")
    func timeoutPublisher() async throws {
        let publisher = Deferred {
            Future<String, Error> { _ in
                // never completes — will be cancelled by timeout
            }
        }
        .withNetworkResilience(maxRetries: 0, baseDelay: 0.01, timeout: 0.05)

        do {
            _ = try await awaitPublisher(publisher)
            Issue.record("Expected timeout error")
        } catch {
            // Timeout causes finished-without-value — caught as error
        }
    }

    // MARK: - Helpers

    private func awaitPublisher<P: Publisher>(
        _ publisher: P
    ) async throws -> P.Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var hasValue = false
            var resumed = false

            cancellable = publisher
                .sink(
                    receiveCompletion: { completion in
                        guard !resumed else { return }
                        _ = cancellable // retain
                        switch completion {
                        case .finished:
                            if !hasValue {
                                resumed = true
                                continuation.resume(throwing: URLError(.timedOut))
                            }
                        case let .failure(error):
                            resumed = true
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        guard !resumed else { return }
                        hasValue = true
                        resumed = true
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}
