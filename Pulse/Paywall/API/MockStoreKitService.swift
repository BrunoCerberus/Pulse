//
//  MockStoreKitService.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Combine
import Foundation
import StoreKit

/// Mock implementation of StoreKitService for testing and previews.
///
/// This mock provides predictable behavior for unit tests and SwiftUI previews
/// without requiring actual StoreKit transactions.
final class MockStoreKitService: StoreKitService {
    // MARK: - Properties

    private let subscriptionStatusSubject: CurrentValueSubject<Bool, Never>
    private var shouldFailPurchase = false
    private var shouldFailRestore = false

    var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        subscriptionStatusSubject.eraseToAnyPublisher()
    }

    var isPremium: Bool {
        subscriptionStatusSubject.value
    }

    // MARK: - Initialization

    init(isPremium: Bool = false) {
        subscriptionStatusSubject = CurrentValueSubject<Bool, Never>(isPremium)
    }

    // MARK: - Configuration for Testing

    func configurePurchaseFailure(_ shouldFail: Bool) {
        shouldFailPurchase = shouldFail
    }

    func configureRestoreFailure(_ shouldFail: Bool) {
        shouldFailRestore = shouldFail
    }

    func setSubscriptionStatus(_ isPremium: Bool) {
        subscriptionStatusSubject.send(isPremium)
    }

    // MARK: - StoreKitService Implementation

    func fetchProducts() -> AnyPublisher<[Product], Error> {
        // Return empty array for mock - products require actual StoreKit configuration
        Just([Product]())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func purchase(_: Product) -> AnyPublisher<Bool, Error> {
        if shouldFailPurchase {
            return Fail(error: StoreKitError.purchaseFailed)
                .eraseToAnyPublisher()
        }

        subscriptionStatusSubject.send(true)
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func restorePurchases() -> AnyPublisher<Bool, Error> {
        if shouldFailRestore {
            return Fail(error: StoreKitError.unknown)
                .eraseToAnyPublisher()
        }

        return Just(isPremium)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func checkSubscriptionStatus() -> AnyPublisher<Bool, Never> {
        Just(isPremium)
            .eraseToAnyPublisher()
    }
}
