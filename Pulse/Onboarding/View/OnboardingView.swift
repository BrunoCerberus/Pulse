import EntropyCore
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                skipButton

                TabView(selection: pageBinding) {
                    ForEach(OnboardingPage.allCases) { page in
                        OnboardingPageView(page: page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomControls
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.3),
                Color.blue.opacity(0.2),
                Color.black,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        HStack {
            Spacer()
            if !viewModel.viewState.isLastPage {
                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .onSkipTapped)
                } label: {
                    Text(String(localized: "onboarding.skip"))
                        .font(Typography.labelMedium)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: Spacing.xl) {
            pageIndicator

            actionButton
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
    }

    private var pageIndicator: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(OnboardingPage.allCases) { page in
                Capsule()
                    .fill(page == viewModel.viewState.currentPage ? Color.white : Color.white.opacity(0.3))
                    .frame(
                        width: page == viewModel.viewState.currentPage ? 24 : 8,
                        height: 8
                    )
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.viewState.currentPage)
            }
        }
    }

    private var actionButton: some View {
        Button {
            HapticManager.shared.buttonPress()
            viewModel.handle(event: .onNextTapped)
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(viewModel.viewState.isLastPage
                    ? String(localized: "onboarding.get_started")
                    : String(localized: "onboarding.next"))
                    .font(Typography.labelLarge)

                if !viewModel.viewState.isLastPage {
                    Image(systemName: "arrow.right")
                        .font(Typography.labelMedium)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                viewModel.viewState.isLastPage
                    ? AnyShapeStyle(Color.Accent.warmGradient)
                    : AnyShapeStyle(Color.white.opacity(0.15))
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(Color.white.opacity(viewModel.viewState.isLastPage ? 0 : 0.2), lineWidth: 1)
            )
        }
        .pressEffect()
    }

    // MARK: - Page Binding

    private var pageBinding: Binding<OnboardingPage> {
        Binding(
            get: { viewModel.viewState.currentPage },
            set: { viewModel.handle(event: .onPageChanged($0)) }
        )
    }
}

#Preview("Onboarding") {
    OnboardingView(viewModel: OnboardingViewModel(serviceLocator: .preview))
        .preferredColorScheme(.dark)
}
