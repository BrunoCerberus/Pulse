//
//  PaywallView.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import StoreKit
import SwiftUI

/// Paywall view for premium subscription purchases.
///
/// This view uses the native SwiftUI `SubscriptionStoreView` for iOS 17+
/// which provides a native paywall experience with Apple's design guidelines.
struct PaywallView: View {
    @StateObject var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss

    /// The subscription group ID matching App Store Connect configuration.
    private let subscriptionGroupID = LiveStoreKitService.subscriptionGroupID

    init(viewModel: PaywallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(
                            action: { dismiss() },
                            label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        )
                    }
                }
        }
        .onAppear {
            viewModel.handle(event: .viewDidAppear)
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            loadingView

        case .success:
            subscriptionStoreContent

        case let .error(message):
            errorView(message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text(Localizable.paywall.loading)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(Localizable.paywall.errorTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(Localizable.paywall.retry) {
                viewModel.handle(event: .viewDidAppear)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
    }

    /// Check if running in test environment where SubscriptionStoreView doesn't render properly.
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    @ViewBuilder
    private var subscriptionStoreContent: some View {
        // Use fallback view in tests since SubscriptionStoreView requires live StoreKit connection
        if #available(iOS 17.0, *), !isRunningTests {
            SubscriptionStoreView(groupID: subscriptionGroupID) {
                paywallMarketingContent
            }
            .subscriptionStoreButtonLabel(.multiline)
            .subscriptionStorePickerItemBackground(.thinMaterial)
            .storeButton(.visible, for: .restorePurchases)
            .onInAppPurchaseCompletion { _, result in
                switch result {
                case .success:
                    dismiss()
                case .failure:
                    break
                }
            }
            .background(backgroundGradient)
        } else {
            fallbackPaywallView
        }
    }

    @ViewBuilder
    private var paywallMarketingContent: some View {
        VStack(spacing: 24) {
            // Premium Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.yellow.opacity(0.8),
                                Color.orange.opacity(0.8),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)

                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .padding(.top, 20)

            // Title
            Text(Localizable.paywall.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(Localizable.paywall.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Features List
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "newspaper.fill",
                    iconColor: .blue,
                    title: Localizable.paywall.feature1Title,
                    description: Localizable.paywall.feature1Description
                )

                FeatureRow(
                    icon: "bookmark.fill",
                    iconColor: .orange,
                    title: Localizable.paywall.feature2Title,
                    description: Localizable.paywall.feature2Description
                )

                FeatureRow(
                    icon: "sparkles",
                    iconColor: .purple,
                    title: Localizable.paywall.feature3Title,
                    description: Localizable.paywall.feature3Description
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    private var fallbackPaywallView: some View {
        ScrollView {
            VStack(spacing: 24) {
                paywallMarketingContent

                // Manual product selection for older iOS
                VStack(spacing: 12) {
                    ForEach(viewModel.products, id: \.id) { product in
                        ProductButton(
                            product: product,
                            isSelected: viewModel.selectedProduct?.id == product.id,
                            onSelect: { viewModel.handle(event: .productSelected(product)) },
                            onPurchase: { viewModel.handle(event: .purchaseRequested(product)) }
                        )
                    }
                }
                .padding(.horizontal, 20)

                // Restore Purchases Button
                Button(
                    action: { viewModel.handle(event: .restorePurchasesTapped) },
                    label: {
                        Text(Localizable.paywall.restorePurchases)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
                .padding(.bottom, 20)
            }
        }
        .background(backgroundGradient)
        .overlay {
            if viewModel.isPurchasing || viewModel.isRestoring {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.systemGray6).opacity(0.3),
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Feature Row Component

private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Product Button Component

private struct ProductButton: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.headline)
                        .foregroundColor(.blue)

                    if let subscription = product.subscription {
                        Text(subscription.subscriptionPeriod.debugDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Coordinator

enum PaywallCoordinator {
    @MainActor
    static func start(serviceLocator: ServiceLocator) -> some View {
        PaywallView(viewModel: PaywallViewModel(serviceLocator: serviceLocator))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var viewModel = PaywallViewModel(serviceLocator: .preview)
    return PaywallView(viewModel: viewModel)
}
