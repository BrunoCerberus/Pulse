import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.localized("settings.title")
    }

    static var viewGithub: String {
        AppLocalization.localized("settings.view_github")
    }

    static var signOut: String {
        AppLocalization.localized("account.sign_out")
    }

    static var signOutConfirm: String {
        AppLocalization.localized("account.sign_out.confirm")
    }

    static var cancel: String {
        AppLocalization.localized("common.cancel")
    }

    static var version: String {
        AppLocalization.localized("common.version")
    }

    static var notifications: String {
        AppLocalization.localized("settings.notifications")
    }

    static var enableNotifications: String {
        AppLocalization.localized("settings.enable_notifications")
    }

    static var breakingNewsAlerts: String {
        AppLocalization.localized("settings.breaking_news_alerts")
    }

    static var contentLanguage: String {
        AppLocalization.localized("settings.content_language")
    }

    static var contentLanguageLabel: String {
        AppLocalization.localized("settings.content_language.label")
    }

    static var appearance: String {
        AppLocalization.localized("settings.appearance")
    }

    static var useSystemTheme: String {
        AppLocalization.localized("settings.use_system_theme")
    }

    static var darkMode: String {
        AppLocalization.localized("settings.dark_mode")
    }

    static var data: String {
        AppLocalization.localized("settings.data")
    }

    static var readingHistory: String {
        AppLocalization.localized("settings.reading_history")
    }

    static var about: String {
        AppLocalization.localized("settings.about")
    }
}

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
        Section(Constants.notifications) {
            Toggle(
                Constants.enableNotifications,
                isOn: Binding(
                    get: { viewModel.viewState.notificationsEnabled },
                    set: { viewModel.handle(event: .onToggleNotifications($0)) }
                )
            )

            Toggle(Constants.breakingNewsAlerts, isOn: Binding(
                get: { viewModel.viewState.breakingNewsEnabled },
                set: { viewModel.handle(event: .onToggleBreakingNews($0)) }
            ))
            .disabled(!viewModel.viewState.notificationsEnabled)
        }
    }

    private var contentLanguageSection: some View {
        Section(Constants.contentLanguage) {
            Picker(
                Constants.contentLanguageLabel,
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
        Section(Constants.appearance) {
            Toggle(Constants.useSystemTheme, isOn: Binding(
                get: { viewModel.viewState.useSystemTheme },
                set: { viewModel.handle(event: .onToggleSystemTheme($0)) }
            ))

            if !viewModel.viewState.useSystemTheme {
                Toggle(Constants.darkMode, isOn: Binding(
                    get: { viewModel.viewState.isDarkMode },
                    set: { viewModel.handle(event: .onToggleDarkMode($0)) }
                ))
            }
        }
    }

    private var dataSection: some View {
        Section(Constants.data) {
            NavigationLink(value: Page.readingHistory) {
                Label(
                    Constants.readingHistory,
                    systemImage: "clock.arrow.circlepath"
                )
            }
        }
    }

    private var aboutSection: some View {
        Section(Constants.about) {
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
    .preferredColorScheme(.dark)
}

enum SettingsCoordinator {
    static func start(serviceLocator: ServiceLocator) -> some View {
        SettingsView(serviceLocator: serviceLocator)
    }
}
