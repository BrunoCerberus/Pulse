import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.shared.localized("settings.title")
    }

    static var viewGithub: String {
        AppLocalization.shared.localized("settings.view_github")
    }

    static var signOut: String {
        AppLocalization.shared.localized("account.sign_out")
    }

    static var signOutConfirm: String {
        AppLocalization.shared.localized("account.sign_out.confirm")
    }

    static var cancel: String {
        AppLocalization.shared.localized("common.cancel")
    }

    static var version: String {
        AppLocalization.shared.localized("common.version")
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
        Section(AppLocalization.shared.localized("settings.notifications")) {
            Toggle(
                AppLocalization.shared.localized("settings.enable_notifications"),
                isOn: Binding(
                    get: { viewModel.viewState.notificationsEnabled },
                    set: { viewModel.handle(event: .onToggleNotifications($0)) }
                )
            )

            Toggle(AppLocalization.shared.localized("settings.breaking_news_alerts"), isOn: Binding(
                get: { viewModel.viewState.breakingNewsEnabled },
                set: { viewModel.handle(event: .onToggleBreakingNews($0)) }
            ))
            .disabled(!viewModel.viewState.notificationsEnabled)
        }
    }

    private var contentLanguageSection: some View {
        Section(AppLocalization.shared.localized("settings.content_language")) {
            Picker(
                AppLocalization.shared.localized("settings.content_language.label"),
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
        Section(AppLocalization.shared.localized("settings.appearance")) {
            Toggle(AppLocalization.shared.localized("settings.use_system_theme"), isOn: Binding(
                get: { viewModel.viewState.useSystemTheme },
                set: { viewModel.handle(event: .onToggleSystemTheme($0)) }
            ))

            if !viewModel.viewState.useSystemTheme {
                Toggle(AppLocalization.shared.localized("settings.dark_mode"), isOn: Binding(
                    get: { viewModel.viewState.isDarkMode },
                    set: { viewModel.handle(event: .onToggleDarkMode($0)) }
                ))
            }
        }
    }

    private var dataSection: some View {
        Section(AppLocalization.shared.localized("settings.data")) {
            NavigationLink(value: Page.readingHistory) {
                Label(
                    AppLocalization.shared.localized("settings.reading_history"),
                    systemImage: "clock.arrow.circlepath"
                )
            }
        }
    }

    private var aboutSection: some View {
        Section(AppLocalization.shared.localized("settings.about")) {
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
