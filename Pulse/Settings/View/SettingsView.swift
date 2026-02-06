import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = String(localized: "settings.title")
    static let viewGithub = String(localized: "settings.view_github")
    static let signOut = String(localized: "account.sign_out")
    static let signOutConfirm = String(localized: "account.sign_out.confirm")
    static let cancel = String(localized: "common.cancel")
    static let version = String(localized: "common.version")
}

// MARK: - SettingsView

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var paywallViewModel: PaywallViewModel

    private let serviceLocator: ServiceLocator

    @State private var isPaywallPresented = false
    @State private var isPremium = false

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: SettingsViewModel(serviceLocator: serviceLocator))
        _paywallViewModel = StateObject(wrappedValue: PaywallViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            List {
                SettingsAccountSection(
                    currentUser: viewModel.viewState.currentUser,
                    onSignOutTapped: { viewModel.handle(event: .onSignOutTapped) }
                )

                SettingsPremiumSection(
                    isPremium: isPremium,
                    onUpgradeTapped: { isPaywallPresented = true }
                )

                notificationsSection
                securitySection
                appearanceSection

                SettingsMutedContentSection(
                    mutedSources: viewModel.viewState.mutedSources,
                    mutedKeywords: viewModel.viewState.mutedKeywords,
                    newMutedSource: Binding(
                        get: { viewModel.viewState.newMutedSource },
                        set: { viewModel.handle(event: .onNewMutedSourceChanged($0)) }
                    ),
                    newMutedKeyword: Binding(
                        get: { viewModel.viewState.newMutedKeyword },
                        set: { viewModel.handle(event: .onNewMutedKeywordChanged($0)) }
                    ),
                    onAddMutedSource: { viewModel.handle(event: .onAddMutedSource) },
                    onRemoveMutedSource: { viewModel.handle(event: .onRemoveMutedSource($0)) },
                    onAddMutedKeyword: { viewModel.handle(event: .onAddMutedKeyword) },
                    onRemoveMutedKeyword: { viewModel.handle(event: .onRemoveMutedKeyword($0)) }
                )

                aboutSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Constants.title)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .alert(Constants.signOut, isPresented: Binding(
            get: { viewModel.viewState.showSignOutConfirmation },
            set: { _ in viewModel.handle(event: .onCancelSignOut) }
        )) {
            Button(Constants.cancel, role: .cancel) {
                HapticManager.shared.tap()
                viewModel.handle(event: .onCancelSignOut)
            }
            Button(Constants.signOut, role: .destructive) {
                HapticManager.shared.notification(.warning)
                viewModel.handle(event: .onConfirmSignOut)
            }
        } message: {
            Text(Constants.signOutConfirm)
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
            checkPremiumStatus()
        }
        .sheet(
            isPresented: $isPaywallPresented,
            onDismiss: { checkPremiumStatus() },
            content: { PaywallView(viewModel: paywallViewModel) }
        )
    }

    private func checkPremiumStatus() {
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            isPremium = storeKitService.isPremium
        } catch {
            isPremium = false
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: Binding(
                get: { viewModel.viewState.notificationsEnabled },
                set: { viewModel.handle(event: .onToggleNotifications($0)) }
            ))

            Toggle("Breaking News Alerts", isOn: Binding(
                get: { viewModel.viewState.breakingNewsEnabled },
                set: { viewModel.handle(event: .onToggleBreakingNews($0)) }
            ))
            .disabled(!viewModel.viewState.notificationsEnabled)
        }
    }

    private var securitySection: some View {
        Section("Security") {
            Toggle(viewModel.viewState.biometricName, isOn: Binding(
                get: { viewModel.viewState.isBiometricEnabled },
                set: { viewModel.handle(event: .onToggleBiometric($0)) }
            ))
            .disabled(!viewModel.viewState.isBiometricAvailable)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle("Use System Theme", isOn: Binding(
                get: { viewModel.viewState.useSystemTheme },
                set: { viewModel.handle(event: .onToggleSystemTheme($0)) }
            ))

            if !viewModel.viewState.useSystemTheme {
                Toggle("Dark Mode", isOn: Binding(
                    get: { viewModel.viewState.isDarkMode },
                    set: { viewModel.handle(event: .onToggleDarkMode($0)) }
                ))
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text(Constants.version)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com/BrunoCerberus/Pulse")!) {
                Label(Constants.viewGithub, systemImage: "link")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(serviceLocator: .preview)
    }
}

enum SettingsCoordinator {
    static func start(serviceLocator: ServiceLocator) -> some View {
        SettingsView(serviceLocator: serviceLocator)
    }
}
