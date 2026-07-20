import EntropyCore
@testable import Pulse
import Testing

/// Coverage for `HomeView`'s Smart Briefing section (only renders when
/// `smartBriefingViewModel.viewState.isVisible` is true, i.e. Premium).
/// Kept separate from `HomeViewSnapshotTests` rather than adding a premium
/// `StoreKitService` to its shared `setUp` — evaluating `.body` here confirms
/// the section renders without crashing, without risking a repeat of the
/// `.buttonStyle(.glassProminent)` blank-canvas issue (AGENTS.md rule 37)
/// affecting the many existing, currently-passing HomeView snapshot references.
@Suite("HomeView Smart Briefing Section Tests", .serialized)
@MainActor
struct HomeViewSmartBriefingCoverageTests {
    @Test("HomeView body evaluates with the Smart Briefing section visible for Premium users")
    func bodyEvaluatesWithSmartBriefingVisible() async {
        let serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(ForYouService.self, instance: MockForYouService())
        serviceLocator.register(InterestProfileService.self, instance: MockInterestProfileService())
        serviceLocator.register(RemoteConfigService.self, instance: MockRemoteConfigService())
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
        serviceLocator.register(StoreKitService.self, instance: MockStoreKitService(isPremium: true))

        let homeViewModel = HomeViewModel(serviceLocator: serviceLocator)
        let forYouViewModel = ForYouViewModel(serviceLocator: serviceLocator)
        let smartBriefingViewModel = SmartBriefingViewModel(serviceLocator: serviceLocator)

        let visible = await waitForCondition(timeout: 1_000_000_000) { @MainActor in
            smartBriefingViewModel.viewState.isVisible
        }
        #expect(visible, "Smart Briefing should be visible once the Premium entitlement is seeded")

        let view = HomeView(
            router: HomeNavigationRouter(),
            viewModel: homeViewModel,
            forYouViewModel: forYouViewModel,
            smartBriefingViewModel: smartBriefingViewModel,
        )
        _ = view.body
    }
}
