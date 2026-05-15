# Pulse — Agent Guidelines

See `CLAUDE.md` for the architecture overview, project structure, key files, and deeplinks. This file defines the rules agents must follow when changing the codebase.

## Build & Test

```bash
make setup | build | build-release
make test | test-unit | test-ui | test-snapshot | test-debug
make lint | format | coverage
make bump-{patch,minor,major} | clean | clean-packages | docs
```

## Coding Style

- **PascalCase** types; **camelCase** funcs/vars; protocols end in `-ing`, `-able`, or `-Service`.
- ViewModel file layout: imports → type → typealiases → `@Published viewState` → private deps → `init` → `handle(event:)` → private `setupBindings()`.
- Views: `@StateObject` owns the VM; push lifecycle through the event pipeline (`onAppear → .onAppear` event).
- No comments explaining *what* code does — only non-obvious *why*.
- Don't add features, error handling, or abstractions beyond what the task needs.

### ViewModel skeleton

```swift
final class HomeViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = HomeViewState
    typealias ViewEvent = HomeViewEvent

    @Published private(set) var viewState: HomeViewState = .initial
    private let interactor: HomeDomainInteractor
    private let eventMap = HomeEventActionMap()
    private let reducer = HomeViewStateReducer()
    private var cancellables = Set<AnyCancellable>()

    init(interactor: HomeDomainInteractor) {
        self.interactor = interactor
        setupBindings()
    }

    func handle(event: HomeViewEvent) {
        guard let action = eventMap.map(event: event) else { return }
        interactor.dispatch(action: action)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { [reducer] in reducer.reduce(domainState: $0) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
```

## Testing

### Unit (Swift Testing)

```swift
@Suite @MainActor
struct HomeDomainInteractorTests {
    let mockNewsService = MockNewsService()
    let mockStorageService = MockStorageService()
    let serviceLocator = ServiceLocator()
    let sut: HomeDomainInteractor

    init() {
        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        sut = HomeDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Load initial data updates state")
    func testLoadInitialData() async {
        mockNewsService.breakingNewsResult = .success([Article.mock()])
        sut.dispatch(action: .loadInitialData)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(!sut.statePublisher.value.isLoading)
    }
}
```

- Fresh `ServiceLocator` per test (never shared). Mocks in `Configs/Mocks/` expose `Result` properties to pick success/failure.
- **UI tests** — `performAccessibilityAudit()` on every main screen. `MOCK_PREMIUM=1` in launch env for premium flows.
- **Snapshot tests** — cover loading/empty/error, Dynamic Type (`iPhoneAirAccessibility`, `iPhoneAirExtraExtraLarge`), and iPad (`iPad` 1024×768, `iPadPro13` 1032×1376 with `horizontalSizeClass: .regular` + `userInterfaceIdiom: .pad`). Never lower precision — re-record references if layout changed.

## Architecture Rules

1. **UDF direction**: View → ViewModel → Interactor → Service. Views never touch services; ViewModels never touch APIs.
2. **Domain is UI-agnostic** — no `SwiftUI` imports in `Domain/`.
3. **DI only via `ServiceLocator`**.
4. **State is immutable** — `Equatable` structs for `DomainState` / `ViewState`.
5. **Auth-gated root** — `RootView` switches `SignInView` / `OnboardingView` / `CoordinatorView` off `AuthenticationManager` (singleton).
6. **Onboarding shown once** — `@AppStorage("pulse.hasCompletedOnboarding")` + `OnboardingService`.
7. **Premium gates** — check `StoreKitService.isPremium` (via `subscriptionStatusPublisher`) before Feed content and the summarization sheet.
8. **Decorators for cross-cutting concerns** — e.g. `CachingNewsService` wraps `LiveNewsService`.
9. **Single backend** — all Live services hit Supabase; aggregation happens in the Go `pulse-backend`.
10. **Offline resilience** — L1+L2 tiered cache, `NetworkMonitorService`, failed refresh preserves existing content.
11. **Analytics is optional** — `try? serviceLocator.retrieve(AnalyticsService.self)`; every event doubles as a Crashlytics breadcrumb.
12. **Language threading** — all services, cache keys, and interactors accept `language` from `UserPreferences.preferredLanguage`; Supabase adds `?language=eq.<lang>`; interactors listen for `.userPreferencesDidChange`.
13. **Localization** — `AppLocalization.shared.localized("key")`. Use `static var` computed (never `static let`) for localized constants; `static let` on enums caches forever and won't re-evaluate on language switch. Constants enums with localized strings must be private at file scope (not nested in generic types).
14. **Dynamic Type** — `@Environment(\.dynamicTypeSize)`; switch to vertical stacks at `.accessibility1`+ via `DynamicTypeSize.isAccessibilitySize`; bump `lineLimit` at accessibility sizes.
15. **VoiceOver** — section titles get `.accessibilityAddTraits(.isHeader)`; `@AccessibilityFocusState` for post-async focus; post `AccessibilityNotification.Announcement` for state changes.
16. **Input validation at boundaries** — YouTube ID regex, HTTPS-only URL allowlist, deeplink ID allowlist + path-traversal rejection, disk cache filename sanitization, 256-char search limit.
17. **Sign-out and account deletion** both call `SettingsViewModel.clearAllUserData()` (SwiftData + L1+L2 + keychain + UserDefaults + ThemeManager + widget data). `AuthService.deleteAccount(presenting:)` handles `requiresRecentLogin` by reauthenticating with the original provider (Apple Guideline 5.1.1(v)). Firebase `User` calls use `withCheckedThrowingContinuation` so the non-Sendable `User` never crosses `await`.
18. **Env-var API key fallbacks are `#if DEBUG`-only**. Remote Config values validated ≥10 chars.
19. **Main-thread Combine sinks** — every `.sink` in a `@MainActor` interactor that mutates `stateSubject.value` **must** precede it with `.receive(on: DispatchQueue.main)`. Without it, mutations crash `_dispatch_assert_queue_fail`.
20. **Swift 6.2 Sendable** — `UncheckedSendableBox` wraps non-Sendable values for `Task` capture; `WeakRef` instead of `[weak self]` in `sending` closures; `nonisolated(unsafe)` for static formatters; cross-isolation protocols conform to `Sendable`.
21. **Liquid Glass for floating UI** — `.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glassProminent)` for toolbars, chips, buttons, badges, skeletons, and bottom-of-card title overlays. **Don't** use `.glassEffect` on large content panels that fill the screen — the static snapshot rendering loses content text (see `ArticleDetailView` / `MediaDetailView` content cards, where `.regularMaterial` + `.clipShape` is the right tool). `.ultraThickMaterial` is allowed for full-bleed privacy backdrops (`AppLockOverlayView`); `.thinMaterial` is allowed when forced by an Apple SDK API surface (`subscriptionStorePickerItemBackground`).
22. **System integrations funnel through `DeeplinkManager`** — App Intents, Quick Actions, Share Extension, push handlers. All `AppIntent`s set `openAppWhenRun = true`.
23. **Share Extension ≠ LLM host** — Gemma 3 1B (~600 MB) ≫ extension's ~120 MB budget. Write `SharedURLItem` to `SharedURLQueue` and open `pulse://shared`; main app drains on foreground. Never load `LLMModelManager` from the extension.
24. **Live Activities owned by the Interactor** — `TTSLiveActivityController` start/update/end is driven by `ArticleDetailDomainInteractor` in lockstep with `LiveTextToSpeechService`. Never call the controller from views. Interactive Live Activity buttons (pause from Lock Screen) are not yet wired — would require `AppIntent`s inside `ActivityConfiguration`.
25. **Quick Actions registered at scene-connect** (not in `Info.plist`) so titles localize via `AppLocalization`. Extend `QuickActionType` + en/pt/es strings + `QuickActionHandler` for new ones.
26. **CloudKit sync is always on, zero-UI**. Container `iCloud.com.bruno.Pulse-News`. Syncs `BookmarkedArticle`, `ReadArticle`, `UserPreferencesModel`, `InterestTopicModel`. Every `@Model` property needs a default; no `@Attribute(.unique)` — enforce uniqueness in the service layer (fetch-before-upsert in `LiveStorageService.markArticleAsRead`). `CloudSyncDomainInteractor` posts `.cloudSyncDidComplete`; Bookmarks / ReadingHistory / Settings / Home reload on it. Tests pass `inMemory: true` (forces CloudKit off). App lock, onboarding, theme, push tokens, caches, and `PendingEngagementEvent` (which has its own non-CloudKit `ModelContainer` in `LiveEngagementEventsService`) are NOT synced.
27. **iPad adaptive layouts via size class, not idiom** — iPad Slide Over reports compact and should render the tab bar. Lists: `LazyVStack` (compact) vs `LazyVGrid(.adaptive(minimum: 360))` (regular). `ArticleDetailView` caps at 720pt on regular width via `HStack { Spacer; content; Spacer }`.
28. **Card widths come from the caller** — `HeroNewsCard` / `FeaturedMediaCard` take a `cardWidth` parameter (defaults 300 / 280). iPad regular passes 380 / 360. At accessibility Dynamic Type sizes, wrap the carousel card in `GeometryReader { proxy in HeroNewsCard(cardWidth: proxy.size.width, ...) }.aspectRatio(300/200, contentMode: .fit)`. Never reintroduce a `UIApplication` screen-width probe — breaks split-view, Catalyst, multitasking.
29. **Mac Catalyst is blocked at the SPM level** — `SUPPORTS_MACCATALYST: false`. `swift-llama-cpp` xcframework has no Catalyst slice, so source-level `#if` guards aren't enough. To re-enable: (a) rebuild the xcframework with a Catalyst slice or fork `Package.swift` to exclude Catalyst, (b) put the Catalyst LLM stub in a standalone file so `LLMModelManager.swift` stays unchanged, (c) `#if !targetEnvironment(macCatalyst)` around `ActivityKit` and `UIApplicationShortcutItem`, (d) conditionalize `PRODUCT_BUNDLE_IDENTIFIER` with `[sdk=macosx*]` — NOT the deprecated `DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER`.
30. **FaceID/TouchID and scene lifecycle** — biometric prompts fire `sceneWillResignActive` / `sceneDidBecomeActive` without `sceneDidEnterBackground`. Any re-lock logic in `sceneDidBecomeActive` must guard against this with an `isAuthenticating` flag set before `LAContext.evaluatePolicy()` and cleared in `defer`, or the app immediately re-locks after successful auth.
31. **Personalization is opportunistic, not load-bearing.** `LiveTopicExtractionService` runs the on-device LLM to extract topics from articles the user reads; container failures and extraction errors are non-fatal (services no-op, log at `warning`). `LiveEngagementEventsService` owns a **separate `ModelContainer`** for `PendingEngagementEvent` because engagement signals are per-device by design (no CloudKit). `ForYouCarouselView` is embedded inside `HomeView` and bubbles taps up via an `onArticleTapped` callback rather than owning its own navigation — same pattern as Home's breaking-news and recently-read carousels.
32. **For You Settings is the only personalization UI surface.** Reach it via `Page.forYouSettings` from Settings. Supported actions on `ForYouSettingsDomainInteractor`: `loadProfile`, `removeTopic(topicID:)`, and a confirmed reset (`requestReset` → `confirmReset` / `cancelReset`) that wipes every topic. New personalization affordances belong here.
33. **Privacy conformance gates PR merges via deterministic code checks** in `.github/workflows/lgpd-conformance.yml` (Brazil — Lei 13.709/2018) and `.github/workflows/gdpr-conformance.yml` (EU 2016/679 + CCPA / CPRA, Cal. Civ. Code §1798.100 et seq., folded together because the regimes overlap ~80%). Both mirror the shape of the same-named workflows in `pulse-backend` so the iOS and backend repos stay in lockstep. Each runs four jobs on push to master + PRs + weekly cron: **PII Scan** (CPF/CNPJ + US SSN regex bans, email allowlist enforcement against `.github/pii-allowlist.txt`, gitleaks with custom rules in `.github/lgpd-gdpr-rules.toml`), **Docs Presence** (README/AGENTS/CLAUDE/`PrivacyInfo.xcprivacy` non-empty; README mentions privacy), **Operational Controls** (clearAllUserData wired from sign-out + delete-account, env-var fallbacks `#if DEBUG`-gated, no plaintext `http://` in networking, CloudKit container `.private(...)`, engagement-events container non-CloudKit), and **Structural Integrity** (`Pulse/PrivacyInfo.xcprivacy` valid plist, every `NSPrivacyCollectedDataType` has a purpose, `*UsageDescription` strings non-empty). No PR-body marker required, no AI review — the deterministic checks have teeth, an AI verdict is rubber-stampable by prompt injection. New third-party SDKs that collect data need a matching `NSPrivacyCollectedDataTypes` entry. New email addresses in source need an entry in `pii-allowlist.txt` (RFC 6761 `@example.com` / `@test.com` domains are wildcarded).

## Common Tasks

### Add a feature
1. Scaffold: `/pulse:scaffold-feature` (or `/pulse:create-feature`).
2. `Service` protocol + Live + Mock → register in `PulseSceneDelegate.registerLiveServices()`.
3. `DomainState` + `DomainAction` + `DomainInteractor` + `EventActionMap` + `ViewStateReducer`.
4. `ViewModel` + `View` (generic over router).
5. `NavigationRouter` + new `Page` case + handle in `Coordinator.build(page:)`.
6. `make generate` → unit + snapshot tests (incl. DT/a11y + iPad size classes).

### Add an endpoint
Add a case to `SupabaseAPI`, implement in the Live service, add the mock counterpart, write a unit test.

### Modify UI
Update `ViewState` → modify `View` → add DT adaptation for horizontal layouts → `.accessibilityAddTraits(.isHeader)` on titles → snapshot tests (base + DT + iPad).

## Commits & PRs

Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`. PR title short (<70 chars); body describes *what* + *why* + manual test steps; include screenshots for UI.

PR-body markers are NOT required by CI (the conformance workflows gate on deterministic code checks, not body text). The `.github/PULL_REQUEST_TEMPLATE.md` still includes optional Summary / Test plan / Notes sections — keep them as habit, but they're documentation discipline, not a gate.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Build fails | `make clean && make generate` |
| Package resolution | `make clean-packages && make setup` |
| Test timeouts | check async `Task.sleep` + `.sink` waits |
| Snapshot mismatch | re-record references (never lower precision) |
| Service not found | verify `PulseSceneDelegate.registerLiveServices()` |
