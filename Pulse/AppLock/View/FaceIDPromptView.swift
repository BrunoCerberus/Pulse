import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.shared.localized("applock.prompt_title")
    }

    static var description: String {
        AppLocalization.shared.localized("applock.prompt_description")
    }

    static var enable: String {
        AppLocalization.shared.localized("applock.prompt_enable")
    }

    static var notNow: String {
        AppLocalization.shared.localized("applock.prompt_not_now")
    }
}

// MARK: - FaceIDPromptView

/// Post-signup bottom sheet prompting the user to enable Face ID app lock.
struct FaceIDPromptView: View {
    @ObservedObject private var lockManager = AppLockManager.shared

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "faceid")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(Constants.title)
                .font(Typography.headlineLarge)
                .multilineTextAlignment(.center)

            Text(Constants.description)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Spacer()

            VStack(spacing: Spacing.md) {
                Button {
                    Task { await lockManager.enableFromPrompt() }
                } label: {
                    Text(Constants.enable)
                        .font(Typography.headlineMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(.tint, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                        .foregroundStyle(.white)
                }

                Button {
                    lockManager.dismissPrompt()
                } label: {
                    Text(Constants.notNow)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    FaceIDPromptView()
        .preferredColorScheme(.dark)
}
