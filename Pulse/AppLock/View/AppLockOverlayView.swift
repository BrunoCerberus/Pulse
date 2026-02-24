import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.shared.localized("applock.locked_title")
    }

    static var unlock: String {
        AppLocalization.shared.localized("applock.unlock")
    }
}

// MARK: - AppLockOverlayView

/// Full-screen lock overlay displayed when the app is locked.
struct AppLockOverlayView: View {
    @ObservedObject private var lockManager = AppLockManager.shared
    @AccessibilityFocusState private var isUnlockFocused: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(Constants.title)
                    .font(Typography.headlineLarge)
                    .foregroundStyle(.primary)

                Button {
                    Task { await lockManager.attemptUnlock() }
                } label: {
                    Label(Constants.unlock, systemImage: "faceid")
                        .font(Typography.headlineMedium)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(.tint, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(Constants.unlock)
                .accessibilityHint(AppLocalization.shared.localized("applock.unlock_hint"))
                .accessibilityFocused($isUnlockFocused)
            }
        }
        .onAppear {
            isUnlockFocused = true
        }
    }
}

#Preview {
    AppLockOverlayView()
        .preferredColorScheme(.dark)
}
