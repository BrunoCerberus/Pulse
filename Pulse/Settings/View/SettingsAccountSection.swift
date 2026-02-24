import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.shared.localized("account.title")
    }

    static var signOut: String {
        AppLocalization.shared.localized("account.sign_out")
    }
}

// MARK: - SettingsAccountSection

struct SettingsAccountSection: View {
    let currentUser: AuthUser?
    let onSignOutTapped: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Section {
            if let user = currentUser {
                profileRow(user: user)
                    .padding(.vertical, Spacing.xs)

                Button(role: .destructive) {
                    HapticManager.shared.buttonPress()
                    onSignOutTapped()
                } label: {
                    Label(Constants.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } header: {
            Text(Constants.title)
                .font(Typography.captionLarge)
        }
    }
}

// MARK: - Profile Row

private extension SettingsAccountSection {
    @ViewBuilder
    func profileRow(user: AuthUser) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: Spacing.sm) {
                ProfileImageView(user: user)

                VStack(spacing: Spacing.xxs) {
                    if let displayName = user.displayName {
                        Text(displayName)
                            .font(Typography.headlineMedium)
                            .foregroundStyle(.primary)
                    }

                    if let email = user.email {
                        Text(email)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: Spacing.md) {
                ProfileImageView(user: user)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    if let displayName = user.displayName {
                        Text(displayName)
                            .font(Typography.headlineMedium)
                            .foregroundStyle(.primary)
                    }

                    if let email = user.email {
                        Text(email)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Profile Image View

private struct ProfileImageView: View {
    let user: AuthUser

    var body: some View {
        if let photoURL = user.photoURL {
            AsyncImageViewer(url: photoURL) {
                InitialPlaceholderView(user: user)
            }
            .scaledToFill()
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .accessibilityLabel(AppLocalization.shared.localized("account.profile_photo"))
        } else {
            InitialPlaceholderView(user: user)
                .accessibilityLabel(AppLocalization.shared.localized("account.user_initial"))
        }
    }
}

private struct InitialPlaceholderView: View {
    let user: AuthUser

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 64, height: 64)

            Text(userInitial)
                .font(.title3)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
        }
    }

    private var userInitial: String {
        if let displayName = user.displayName, let first = displayName.first {
            return String(first).uppercased()
        }
        if let email = user.email, let first = email.first {
            return String(first).uppercased()
        }
        return "U"
    }
}

#Preview {
    SettingsAccountSection(currentUser: AuthUser.mock, onSignOutTapped: {})
        .preferredColorScheme(.dark)
}

#Preview("No User") {
    SettingsAccountSection(currentUser: nil, onSignOutTapped: {})
        .preferredColorScheme(.dark)
}
