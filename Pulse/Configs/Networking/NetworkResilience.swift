import Combine
import EntropyCore
import Foundation

extension Publisher {
    /// Adds retry with exponential backoff and per-attempt timeout to a publisher.
    ///
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 2)
    ///   - baseDelay: Initial delay before first retry in seconds (default: 1.0)
    ///   - timeout: Timeout per attempt in seconds (default: 15.0)
    ///   - scheduler: The scheduler for delays and timeout (default: DispatchQueue.global())
    /// - Returns: A publisher with retry and timeout behavior applied.
    func withNetworkResilience(
        maxRetries: Int = 2,
        baseDelay: TimeInterval = 1.0,
        timeout: TimeInterval = 15.0,
        scheduler: some Scheduler = DispatchQueue.global()
    ) -> AnyPublisher<Output, Failure> {
        self
            .timeout(.seconds(timeout), scheduler: scheduler)
            .retryWithBackoff(maxRetries: maxRetries, baseDelay: baseDelay, scheduler: scheduler)
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    /// Retries a failed publisher with exponential backoff.
    ///
    /// Each retry waits `baseDelay` seconds, doubling on each subsequent attempt.
    /// For example, with baseDelay=1: first retry after 1s, second after 2s.
    /// No mutable state is captured — backoff is derived from recursive parameters.
    func retryWithBackoff(
        maxRetries: Int,
        baseDelay: TimeInterval,
        scheduler: some Scheduler
    ) -> AnyPublisher<Output, Failure> {
        self.catch { error -> AnyPublisher<Output, Failure> in
            guard maxRetries > 0 else {
                Logger.shared.service(
                    "Network retry exhausted",
                    level: .debug
                )
                return Fail(error: error).eraseToAnyPublisher()
            }

            Logger.shared.service(
                "Network retry, \(maxRetries) attempt(s) remaining after \(baseDelay)s delay",
                level: .debug
            )

            return Just(())
                .delay(for: .seconds(baseDelay), scheduler: scheduler)
                .flatMap { _ in
                    self.retryWithBackoff(
                        maxRetries: maxRetries - 1,
                        baseDelay: baseDelay * 2,
                        scheduler: scheduler
                    )
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
