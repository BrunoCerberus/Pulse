import Combine
import EntropyCore
import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var paywallViewModel: PaywallViewModel
    @StateObject private var lockManager = AppLockManager.shared

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

                SettingsSecuritySection(lockManager: lockManager)

                notificationsSection
                contentLanguageSection
                appearanceSection

                dataSection

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
        .navigationTitle(SettingsViewConstants.title)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .alert(SettingsViewConstants.signOut, isPresented: Binding(
            get: { viewModel.viewState.showSignOutConfirmation },
            set: { _ in viewModel.handle(event: .onCancelSignOut) }
        )) {
            Button(SettingsViewConstants.cancel, role: .cancel) {
                HapticManager.shared.tap()
                viewModel.handle(event: .onCancelSignOut)
            }
            Button(SettingsViewConstants.signOut, role: .destructive) {
                HapticManager.shared.notification(.warning)
                viewModel.handle(event: .onConfirmSignOut)
            }
        } message: {
            Text(SettingsViewConstants.signOutConfirm)
        }
        .alert(
            AppLocalization.localized("common.error"),
            isPresented: Binding(
                get: { viewModel.viewState.errorMessage != nil },
                set: { if !$0 { viewModel.handle(event: .onDismissError) } }
            )
        ) {
            Button(AppLocalization.localized("common.ok"), role: .cancel) {
                viewModel.handle(event: .onDismissError)
            }
        } message: {
            Text(viewModel.viewState.errorMessage ?? "")
        }
        .alert(
            AppLocalization.localized("settings.notifications_denied.title"),
            isPresented: Binding(
                get: { viewModel.viewState.showNotificationsDeniedAlert },
                set: { if !$0 { viewModel.handle(event: .onDismissNotificationsDeniedAlert) } }
            )
        ) {
            Button(AppLocalization.localized("common.cancel"), role: .cancel) {
                viewModel.handle(event: .onDismissNotificationsDeniedAlert)
            }
            Button(AppLocalization.localized("settings.notifications_denied.open_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                viewModel.handle(event: .onDismissNotificationsDeniedAlert)
            }
        } message: {
            Text(AppLocalization.localized("settings.notifications_denied.message"))
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
            checkPremiumStatus()
        }
        .onReceive(subscriptionStatusPublisher) { newStatus in
            isPremium = newStatus
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

    private var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        guard let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) else {
            return Empty().eraseToAnyPublisher()
        }
        return storeKitService.subscriptionStatusPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private var notificationsSection: some View {
        Section(SettingsViewConstants.notifications) {
            Toggle(
                SettingsViewConstants.enableNotifications,
                isOn: Binding(
                    get: { viewModel.viewState.notificationsEnabled },
                    set: { viewModel.handle(event: .onToggleNotifications($0)) }
                )
            )

            Toggle(SettingsViewConstants.breakingNewsAlerts, isOn: Binding(
                get: { viewModel.viewState.breakingNewsEnabled },
                set: { viewModel.handle(event: .onToggleBreakingNews($0)) }
            ))
            .disabled(!viewModel.viewState.notificationsEnabled)
        }
    }

    private var contentLanguageSection: some View {
        Section(SettingsViewConstants.contentLanguage) {
            Picker(
                SettingsViewConstants.contentLanguageLabel,
                selection: Binding(
                    get: { viewModel.viewState.selectedLanguage },
                    set: { viewModel.handle(event: .onLanguageChanged($0)) }
                )
            ) {
                ForEach(ContentLanguage.allCases, id: \.self) { language in
                    Text("\(language.flag) \(language.displayName)")
                        .tag(language.rawValue)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section(SettingsViewConstants.appearance) {
            Toggle(SettingsViewConstants.useSystemTheme, isOn: Binding(
                get: { viewModel.viewState.useSystemTheme },
                set: { viewModel.handle(event: .onToggleSystemTheme($0)) }
            ))

            if !viewModel.viewState.useSystemTheme {
                Toggle(SettingsViewConstants.darkMode, isOn: Binding(
                    get: { viewModel.viewState.isDarkMode },
                    set: { viewModel.handle(event: .onToggleDarkMode($0)) }
                ))
            }
        }
    }

    private var dataSection: some View {
        Section(SettingsViewConstants.data) {
            NavigationLink(value: Page.readingHistory) {
                Label(
                    SettingsViewConstants.readingHistory,
                    systemImage: "clock.arrow.circlepath"
                )
            }
        }
    }

    private var aboutSection: some View {
        Section(SettingsViewConstants.about) {
            HStack {
                Text(SettingsViewConstants.version)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }

            if let githubURL = URL(string: "https://github.com/BrunoCerberus/Pulse") {
                Link(destination: githubURL) {
                    Label(SettingsViewConstants.viewGithub, systemImage: "link")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(serviceLocator: .preview)
    }
    .preferredColorScheme(.dark)
}

enum SettingsCoordinator {
    static func start(serviceLocator: ServiceLocator) -> some View {
        SettingsView(serviceLocator: serviceLocator)
    }
}
