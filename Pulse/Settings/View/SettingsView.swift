import EntropyCore
import SwiftUI

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

                topicsSection
                notificationsSection
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

                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(String(localized: "settings.title"))
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .alert(String(localized: "settings.clear_history"), isPresented: Binding(
            get: { viewModel.viewState.showClearHistoryConfirmation },
            set: { _ in viewModel.handle(event: .onCancelClearHistory) }
        )) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                HapticManager.shared.tap()
                viewModel.handle(event: .onCancelClearHistory)
            }
            Button(String(localized: "settings.clear_history.action"), role: .destructive) {
                HapticManager.shared.notification(.warning)
                viewModel.handle(event: .onConfirmClearHistory)
            }
        } message: {
            Text(String(localized: "settings.clear_history.confirm"))
        }
        .alert(String(localized: "account.sign_out"), isPresented: Binding(
            get: { viewModel.viewState.showSignOutConfirmation },
            set: { _ in viewModel.handle(event: .onCancelSignOut) }
        )) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                HapticManager.shared.tap()
                viewModel.handle(event: .onCancelSignOut)
            }
            Button(String(localized: "account.sign_out"), role: .destructive) {
                HapticManager.shared.notification(.warning)
                viewModel.handle(event: .onConfirmSignOut)
            }
        } message: {
            Text(String(localized: "account.sign_out.confirm"))
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

    private var topicsSection: some View {
        Section {
            ForEach(viewModel.viewState.allTopics) { topic in
                Button {
                    viewModel.handle(event: .onToggleTopic(topic))
                } label: {
                    HStack {
                        Label(topic.displayName, systemImage: topic.icon)
                            .foregroundStyle(topic.color)

                        Spacer()

                        if viewModel.viewState.followedTopics.contains(topic) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text(String(localized: "settings.followed_topics"))
        } footer: {
            Text(String(localized: "settings.followed_topics.description"))
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

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                viewModel.handle(event: .onClearReadingHistory)
            } label: {
                Label(String(localized: "settings.clear_history"), systemImage: "trash")
            }
            .accessibilityIdentifier("clearReadingHistoryButton")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text(String(localized: "common.version"))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com/BrunoCerberus/Pulse")!) {
                Label(String(localized: "settings.view_github"), systemImage: "link")
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
