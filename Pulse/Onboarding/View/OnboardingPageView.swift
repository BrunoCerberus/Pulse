import EntropyCore
import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            iconCircle

            VStack(spacing: Spacing.md) {
                Text(page.title)
                    .font(Typography.headlineLarge)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
            Spacer()
        }
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(page.iconColor.opacity(0.15))
                .frame(width: 140, height: 140)

            Circle()
                .fill(page.iconColor.gradient)
                .frame(width: 110, height: 110)

            Image(systemName: page.icon)
                .font(.system(size: 44))
                .foregroundStyle(.white)
        }
        .glowEffect(color: page.iconColor, radius: 20)
    }
}

#Preview("Welcome") {
    ZStack {
        LinearGradient(
            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        OnboardingPageView(page: .welcome)
    }
    .preferredColorScheme(.dark)
}

#Preview("Get Started") {
    ZStack {
        LinearGradient(
            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        OnboardingPageView(page: .getStarted)
    }
    .preferredColorScheme(.dark)
}
