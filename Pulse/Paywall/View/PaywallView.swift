//
//  PaywallView.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import EntropyCore
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
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            HapticManager.shared.tap()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: IconSize.lg))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(String(localized: "paywall.close"))
                    }
                }
        }
        .onAppear {
            viewModel.handle(event: .viewDidAppear)
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                HapticManager.shared.success()
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
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text(Localizable.paywall.loading)
                .font(Typography.captionLarge)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
    }

    private func errorView(_ message: String) -> some View {
        GlassCard(style: .regular, shadowStyle: .elevated, padding: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Semantic.warning)
                    .accessibilityHidden(true)

                Text(Localizable.paywall.errorTitle)
                    .font(Typography.titleMedium)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .viewDidAppear)
                } label: {
                    Text(Localizable.paywall.retry)
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Accent.primary)
                        .clipShape(Capsule())
                }
                .pressEffect()
            }
        }
        .padding(Spacing.lg)
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
            .storeButton(.hidden, for: .cancellation)
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

    private var paywallMarketingContent: some View {
        VStack(spacing: Spacing.lg) {
            // Premium Icon
            ZStack {
                Circle()
                    .fill(Color.Accent.warmGradient)
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.white)
            }
            .glowEffect(color: .orange, radius: 16)
            .padding(.top, Spacing.lg)
            .accessibilityHidden(true)

            // Title
            Text(Localizable.paywall.title)
                .font(Typography.displayMedium)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(Localizable.paywall.subtitle)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)

            // Features List
            VStack(alignment: .leading, spacing: Spacing.md) {
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
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
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
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: IconSize.md))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.headlineMedium)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Product Button Component

private struct ProductButton: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    let onPurchase: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticManager.shared.selectionChanged()
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(product.displayName)
                        .font(Typography.headlineMedium)
                        .foregroundStyle(.primary)

                    Text(product.description)
                        .font(Typography.captionMedium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text(product.displayPrice)
                        .font(Typography.headlineLarge)
                        .foregroundStyle(Color.Accent.primary)

                    if let subscription = product.subscription {
                        Text(subscription.subscriptionPeriod.debugDescription)
                            .font(Typography.captionSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? GlassStyle.regular.material : GlassStyle.thin.material)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .stroke(
                        isSelected ? Color.Accent.primary : Color.Border.adaptive(for: colorScheme),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
            .depthShadow(isSelected ? .medium : .subtle)
        }
        .pressEffect()
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
        .preferredColorScheme(.dark)
}
