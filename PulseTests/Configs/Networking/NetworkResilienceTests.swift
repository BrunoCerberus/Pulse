import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("NetworkResilience Tests")
struct NetworkResilienceTests {
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
        .withNetworkResilience(maxRetries: 2, baseDelay: 0.01, timeout: 5.0)

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
        .withNetworkResilience(maxRetries: 2, baseDelay: 0.01, timeout: 5.0)

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
        .withNetworkResilience(maxRetries: 2, baseDelay: 0.01, timeout: 5.0)

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
        .withNetworkResilience(maxRetries: 0, baseDelay: 0.01, timeout: 5.0)

        do {
            _ = try await awaitPublisher(publisher)
            Issue.record("Expected failure")
        } catch {
            #expect(callCount == 1)
        }
    }

    // MARK: - Helpers

    private func awaitPublisher<P: Publisher>(
        _ publisher: P,
        timeout _: TimeInterval = 10.0
    ) async throws -> P.Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var resumed = false

            cancellable = publisher
                .sink(
                    receiveCompletion: { completion in
                        guard !resumed else { return }
                        resumed = true
                        _ = cancellable // retain
                        switch completion {
                        case .finished:
                            break // value already delivered
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        guard !resumed else { return }
                        resumed = true
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}
