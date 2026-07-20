import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.localized("account.title")
    }

    static var signOut: String {
        AppLocalization.localized("account.sign_out")
    }

    static var deleteAccount: String {
        AppLocalization.localized("account.delete")
    }

    static var profilePhoto: String {
        AppLocalization.localized("account.profile_photo")
    }

    static var userInitial: String {
        AppLocalization.localized("account.user_initial")
    }
}

// MARK: - SettingsAccountSection

struct SettingsAccountSection: View {
    let currentUser: AuthUser?
    let isDeletingAccount: Bool
    let onSignOutTapped: () -> Void
    let onDeleteAccountTapped: () -> Void

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
                .disabled(isDeletingAccount)

                Button(role: .destructive) {
                    HapticManager.shared.buttonPress()
                    onDeleteAccountTapped()
                } label: {
                    if isDeletingAccount {
                        HStack(spacing: Spacing.sm) {
                            ProgressView()
                            Text(Constants.deleteAccount)
                        }
                    } else {
                        Label(Constants.deleteAccount, systemImage: "trash.fill")
                    }
                }
                .disabled(isDeletingAccount)
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
            .accessibilityLabel(Constants.profilePhoto)
        } else {
            InitialPlaceholderView(user: user)
                .accessibilityLabel(Constants.userInitial)
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
    SettingsAccountSection(
        currentUser: AuthUser.mock,
        isDeletingAccount: false,
        onSignOutTapped: {},
        onDeleteAccountTapped: {},
    )
    .preferredColorScheme(.dark)
}

#Preview("No User") {
    SettingsAccountSection(
        currentUser: nil,
        isDeletingAccount: false,
        onSignOutTapped: {},
        onDeleteAccountTapped: {},
    )
    .preferredColorScheme(.dark)
}
