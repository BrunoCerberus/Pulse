import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("PremiumFeature Tests")
struct PremiumFeatureTests {
    // MARK: - Feature Properties

    @Test("Daily Digest feature has correct properties")
    func dailyDigestProperties() {
        let feature = PremiumFeature.dailyDigest

        #expect(feature.icon == "sparkles")
        #expect(feature.title.isEmpty == false)
        #expect(feature.description.isEmpty == false)
    }

    @Test("Article Summarization feature has correct properties")
    func articleSummarizationProperties() {
        let feature = PremiumFeature.articleSummarization

        #expect(feature.icon == "doc.text.magnifyingglass")
        #expect(feature.title.isEmpty == false)
        #expect(feature.description.isEmpty == false)
    }

    @Test("All features have unique icons")
    func allFeaturesHaveUniqueIcons() {
        let features: [PremiumFeature] = [.dailyDigest, .articleSummarization]
        let icons = features.map(\.icon)
        let uniqueIcons = Set(icons)

        #expect(icons.count == uniqueIcons.count, "All features should have unique icons")
    }

    @Test("All features have unique colors")
    func allFeaturesHaveUniqueColors() {
        let features: [PremiumFeature] = [.dailyDigest, .articleSummarization]
        let colors = features.map { "\($0.iconColor)" }
        let uniqueColors = Set(colors)

        #expect(colors.count == uniqueColors.count, "All features should have unique colors")
    }

    @Test("All premium features have non-empty descriptions")
    func allFeaturesHaveNonEmptyDescriptions() {
        let features: [PremiumFeature] = [.dailyDigest, .articleSummarization]

        for feature in features {
            #expect(!feature.description.isEmpty, "\(feature) should have a non-empty description")
        }
    }

    @Test("All premium features have non-empty titles")
    func allFeaturesHaveNonEmptyTitles() {
        let features: [PremiumFeature] = [.dailyDigest, .articleSummarization]

        for feature in features {
            #expect(!feature.title.isEmpty, "\(feature) should have a non-empty title")
        }
    }

    @Test("All premium features have valid SF Symbol icons")
    func allFeaturesHaveValidSFSymbolIcons() {
        let features: [PremiumFeature] = [.dailyDigest, .articleSummarization]

        for feature in features {
            // Verify the icon string is not empty
            #expect(!feature.icon.isEmpty, "\(feature) should have a non-empty icon")

            // Verify the icon can create a valid UIImage (valid SF Symbol)
            let image = UIImage(systemName: feature.icon)
            #expect(image != nil, "\(feature) icon '\(feature.icon)' should be a valid SF Symbol")
        }
    }

    @Test("All premium features have valid icon colors")
    func allFeaturesHaveValidIconColors() {
        let features: [PremiumFeature] = [.dailyDigest, .articleSummarization]

        for feature in features {
            // Just verify that accessing iconColor doesn't crash
            // Color is a non-optional type, so we just verify the property can be accessed
            let color = feature.iconColor
            // Use the color to avoid unused variable warning
            _ = color.description
        }
    }
}

@Suite("MockStoreKitService Premium Status Tests")
struct MockStoreKitServicePremiumTests {
    // MARK: - Premium Status

    @Test("MockStoreKitService returns false for non-premium by default")
    func defaultNonPremium() {
        let service = MockStoreKitService()

        #expect(service.isPremium == false)
    }

    @Test("MockStoreKitService returns true when initialized as premium")
    func initializedAsPremium() {
        let service = MockStoreKitService(isPremium: true)

        #expect(service.isPremium == true)
    }

    @Test("MockStoreKitService can update subscription status")
    func updateSubscriptionStatus() async throws {
        let service = MockStoreKitService(isPremium: false)

        #expect(service.isPremium == false)

        service.setSubscriptionStatus(true)

        #expect(service.isPremium == true)
    }

    @Test("MockStoreKitService publishes subscription status changes")
    func publishesStatusChanges() async throws {
        let service = MockStoreKitService(isPremium: false)
        var receivedStatuses: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        service.subscriptionStatusPublisher
            .sink { receivedStatuses.append($0) }
            .store(in: &cancellables)

        // Initial status
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(receivedStatuses.contains(false))

        // Update status
        service.setSubscriptionStatus(true)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(receivedStatuses.contains(true))
    }
}

@Suite("Premium Gating Integration Tests")
@MainActor
struct PremiumGatingIntegrationTests {
    // MARK: - Service Locator with Premium Status

    @Test("ServiceLocator provides premium status through StoreKitService")
    func serviceLocatorProvidesPremiumStatus() throws {
        let serviceLocator = ServiceLocator()
        let mockStoreKit = MockStoreKitService(isPremium: true)
        serviceLocator.register(StoreKitService.self, instance: mockStoreKit)

        let retrievedService = try serviceLocator.retrieve(StoreKitService.self)

        #expect(retrievedService.isPremium == true)
    }

    @Test("ServiceLocator provides non-premium status through StoreKitService")
    func serviceLocatorProvidesNonPremiumStatus() throws {
        let serviceLocator = ServiceLocator()
        let mockStoreKit = MockStoreKitService(isPremium: false)
        serviceLocator.register(StoreKitService.self, instance: mockStoreKit)

        let retrievedService = try serviceLocator.retrieve(StoreKitService.self)

        #expect(retrievedService.isPremium == false)
    }

    @Test("Premium status can be toggled through ServiceLocator")
    func premiumStatusCanBeToggled() throws {
        let serviceLocator = ServiceLocator()
        let mockStoreKit = MockStoreKitService(isPremium: false)
        serviceLocator.register(StoreKitService.self, instance: mockStoreKit)

        let retrievedService = try serviceLocator.retrieve(StoreKitService.self)
        #expect(retrievedService.isPremium == false)

        mockStoreKit.setSubscriptionStatus(true)

        #expect(retrievedService.isPremium == true)
    }
}
