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
    ///   - scheduler: The scheduler for delays and timeout (default: DispatchQueue.global)
    /// - Returns: A publisher with retry and timeout behavior applied.
    func withNetworkResilience(
        maxRetries: Int = 2,
        baseDelay: TimeInterval = 1.0,
        timeout: TimeInterval = 15.0,
        scheduler: some Scheduler = DispatchQueue.main
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
    /// Each retry waits `baseDelay * 2^attempt` seconds before re-subscribing.
    /// For example, with baseDelay=1: first retry after 1s, second after 2s.
    func retryWithBackoff(
        maxRetries: Int,
        baseDelay: TimeInterval,
        scheduler: some Scheduler
    ) -> AnyPublisher<Output, Failure> {
        var currentAttempt = 0

        return self.catch { error -> AnyPublisher<Output, Failure> in
            currentAttempt += 1
            guard currentAttempt <= maxRetries else {
                Logger.shared.service(
                    "Network retry exhausted after \(maxRetries) attempts",
                    level: .debug
                )
                return Fail(error: error).eraseToAnyPublisher()
            }

            let delay = baseDelay * pow(2.0, Double(currentAttempt - 1))
            Logger.shared.service(
                "Network retry \(currentAttempt)/\(maxRetries) after \(delay)s delay",
                level: .debug
            )

            return Just(())
                .delay(for: .seconds(delay), scheduler: scheduler)
                .flatMap { _ -> AnyPublisher<Output, Failure> in
                    self.retryWithBackoff(
                        maxRetries: maxRetries - currentAttempt,
                        baseDelay: baseDelay * pow(2.0, Double(currentAttempt)),
                        scheduler: scheduler
                    )
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
