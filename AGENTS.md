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
- Views: tab/root views receive their VM via `@ObservedObject` (constructed by the Coordinator/parent); leaf and sheet views that own the VM's lifetime use `@StateObject`. Push lifecycle through the event pipeline (`onAppear → .onAppear` event).
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

1. **UDF direction**: View → ViewModel → Interactor → Service. Views never touch services; ViewModels never touch APIs. Exception: `FeedView`, `ArticleDetailView`, `SettingsView` hold a `ServiceLocator` and read `StoreKitService` directly for premium entitlement defense-in-depth (rule 7) — not a pattern to copy elsewhere.
2. **Domain is UI-agnostic** — no `SwiftUI` imports in `Domain/`.
3. **DI only via `ServiceLocator`**.
4. **State is immutable** — `Equatable` structs for `DomainState` / `ViewState`.
5. **Auth-gated root** — `RootView` switches `SignInView` / `OnboardingView` / `CoordinatorView` off `AuthenticationManager`.
6. **Onboarding shown once** — `@AppStorage("pulse.hasCompletedOnboarding")` + `OnboardingService`.
7. **Premium gates** — views seed `isPremium` from cached `StoreKitService.isPremium` (`subscriptionStatusPublisher`) for first render, then re-verify via `refreshSubscriptionStatus()` in a `.task` (`FeedView`, `ArticleDetailView`'s summarize button, `SettingsView`). `SummarizationDomainInteractor.startSummarization` and `FeedDomainInteractor.generateDigest` re-`guard` on the cached `isPremium` at the service boundary as defense-in-depth.
8. **Decorators for cross-cutting concerns** — e.g. `CachingNewsService` wraps `LiveNewsService`.
9. **Single backend** — all Live services hit Supabase; aggregation happens in the Go `pulse-backend`.
10. **Offline resilience** — `CachingNewsService`/`CachingMediaService` wrap Live services with L1 (NSCache, 10 min TTL) + L2 (disk JSON, 24 h TTL). Cache-miss fetches use `Publisher.withNetworkResilience()` (2 retries, 1→2s backoff, 15s timeout). Stale L2 served when offline; pull-to-refresh clears L1 only; `NetworkMonitorService` + failed refresh preserves existing content.
11. **Analytics is optional** — `try? serviceLocator.retrieve(AnalyticsService.self)`; every event doubles as a Crashlytics breadcrumb.
12. **Language threading** — services, cache keys, and interactors accept `language` from `UserPreferences.preferredLanguage`; Supabase adds `?language=eq.<lang>`; interactors listen for `.userPreferencesDidChange`.
13. **Localization** — `AppLocalization.shared.localized("key")`. `static var` (never `static let`) for localized constants — `static let` on enums caches forever and won't re-evaluate on language switch. Localized-string constants enums must be file-scope private, not nested in generic types.
14. **Dynamic Type** — `@Environment(\.dynamicTypeSize)`; vertical stacks at `.accessibility1`+ via `DynamicTypeSize.isAccessibilitySize`; bump `lineLimit` at accessibility sizes.
15. **VoiceOver** — section titles get `.accessibilityAddTraits(.isHeader)`; `@AccessibilityFocusState` for post-async focus; `AccessibilityNotification.Announcement` for state changes.
16. **Input validation at boundaries** — YouTube ID regex; HTTPS-only gate (`SafeMediaURL.validated`/`isSafe`) shared across `VideoPlayerView`, `AudioPlayerView`, and both open-in-browser sinks (`MediaDetail`/`ArticleDetailDomainInteractor`); untrusted RSS text through `PromptSanitizer.sanitize(_:maxLength:)` (`Configs/AI/`) in all three prompt builders before LLM interpolation (neutralizes Gemma turn markers, control chars → spaces, strips backticks, length-caps) — also reused for non-LLM untrusted-text display (`TTSLiveActivityController` sanitizes title/source before they render on the Lock Screen); deeplink ID allowlist + path-traversal rejection (`Deeplink.isValidArticleID`); free-text deeplink params stripped/capped via `Deeplink.sanitizedQueryParameter` (`DeeplinkManager`, `NotificationDeeplinkParser`); `SharedURLQueue.isAcceptable` rejects path-traversal (`..`) and control characters on shared URLs; disk cache filename sanitization; 256-char search cap (also enforced in `SearchDomainInteractor`); widget `SharedDataManager` caps decoded arrays at 10 items to bound memory from a poisoned App Group store.
17. **Sign-out and account deletion** both call `SettingsViewModel.clearAllUserData()` — single-flight (`isClearingUserData`) wipe of SwiftData + L1/L2 cache + Keychain + UserDefaults + ThemeManager + widget/Share-Extension App Group data + TTS Live Activity + personalization profile & engagement queue + app-lock state, plus an APNs unregister and a best-effort private CloudKit zone delete (so reinstall-restore can't resurrect erased PII). Same wipe fires from `AuthenticationManager` (`PulseSceneDelegate.configureSessionCleanup`) on any authenticated→unauthenticated transition, de-duped by the single-flight guard. `AuthService.deleteAccount(presenting:)` reauths on `requiresRecentLogin` (Apple Guideline 5.1.1(v)). Firebase `User` calls use `withCheckedThrowingContinuation` (non-Sendable `User` never crosses `await`).
18. **Env-var API key fallbacks are `#if DEBUG`-only**. Remote Config values validated ≥10 chars.
19. **Main-thread Combine sinks** — every `.sink` in a `@MainActor` interactor mutating `stateSubject.value` **must** precede it with `.receive(on: DispatchQueue.main)`, or it crashes `_dispatch_assert_queue_fail`.
20. **Swift 6.2 Sendable** — `UncheckedSendableBox` wraps non-Sendable values for `Task` capture; `WeakRef` instead of `[weak self]` in `sending` closures; `nonisolated(unsafe)` for static formatters; cross-isolation protocols conform to `Sendable`.
21. **Liquid Glass for floating UI** — `.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glassProminent)` for toolbars, chips, buttons, badges, skeletons, card overlays. Not for large content panels — static snapshot rendering loses text (`ArticleDetailView`/`MediaDetailView` content cards use `.regularMaterial` + `.clipShape` instead). `.ultraThickMaterial` OK for full-bleed privacy backdrops (`AppLockOverlayView`); `.thinMaterial` OK where forced by an Apple SDK surface (`subscriptionStorePickerItemBackground`).
22. **System integrations funnel through `DeeplinkManager`** — App Intents, Quick Actions, Share Extension, push handlers. All `AppIntent`s set `openAppWhenRun = true`.
23. **Share Extension ≠ LLM host** — Gemma 3 1B (~600 MB) ≫ extension's ~120 MB budget. Write `SharedURLItem` to `SharedURLQueue`, open `pulse://shared`; main app drains on foreground. Never load `LLMModelManager` from the extension.
24. **Live Activities owned by the playback queue** — `TTSLiveActivityController` start/update/end driven by `LivePlaybackQueueService` in lockstep with `LiveTextToSpeechService`. Never call the controller from views. Lock Screen pause button not yet wired (needs `AppIntent`s inside `ActivityConfiguration`).
25. **Quick Actions registered at scene-connect** (not `Info.plist`) so titles localize. Extend `QuickActionType` + en/pt/es strings + `QuickActionHandler` for new ones.
26. **CloudKit sync is always on, zero-UI**. Container `iCloud.com.bruno.Pulse-News`. Syncs `BookmarkedArticle`, `ReadArticle`, `UserPreferencesModel`, `InterestTopicModel`. Every `@Model` property needs a default; no `@Attribute(.unique)` — enforce uniqueness in the service layer (fetch-before-upsert in `LiveStorageService.markArticleAsRead`). `CloudSyncDomainInteractor` posts `.cloudSyncDidComplete`; Bookmarks/ReadingHistory/Settings/Home reload on it. Tests pass `inMemory: true` (forces CloudKit off). App lock, onboarding, theme, push tokens, caches, and `PendingEngagementEvent` (own non-CloudKit `ModelContainer` in `LiveEngagementEventsService`) are NOT synced.
27. **iPad adaptive layouts via size class, not idiom** — Slide Over reports compact and should still show the tab bar. `LazyVStack` (compact) vs `LazyVGrid(.adaptive(minimum: 360))` (regular). `ArticleDetailView` caps at 720pt on regular width via `HStack { Spacer; content; Spacer }`.
28. **Card widths come from the caller** — `HeroNewsCard`/`FeaturedMediaCard` take `cardWidth` (defaults 300/280; iPad regular passes 380/360). At accessibility Dynamic Type sizes wrap in `GeometryReader { proxy in HeroNewsCard(cardWidth: proxy.size.width, ...) }.aspectRatio(300/200, contentMode: .fit)`. Never reintroduce a `UIApplication` screen-width probe — breaks split-view, Catalyst, multitasking.
29. **Mac Catalyst is blocked at the SPM level** — `SUPPORTS_MACCATALYST: false`; `swift-llama-cpp` xcframework has no Catalyst slice, so source `#if` guards alone aren't enough. To re-enable: (a) rebuild the xcframework with a Catalyst slice or fork `Package.swift` to exclude Catalyst, (b) put the Catalyst LLM stub in a standalone file so `LLMModelManager.swift` stays unchanged, (c) `#if !targetEnvironment(macCatalyst)` around `ActivityKit`/`UIApplicationShortcutItem`, (d) conditionalize `PRODUCT_BUNDLE_IDENTIFIER` with `[sdk=macosx*]` — not the deprecated `DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER`.
30. **FaceID/TouchID and scene lifecycle** — biometric prompts fire `sceneWillResignActive`/`sceneDidBecomeActive` without `sceneDidEnterBackground`. Re-lock logic in `sceneDidBecomeActive` needs an `isAuthenticating` flag set before `LAContext.evaluatePolicy()` and cleared in `defer`, or the app immediately re-locks after successful auth.
31. **Personalization is opportunistic, not load-bearing.** `LiveTopicExtractionService` extracts topics via on-device LLM from read articles; container/extraction failures are non-fatal (no-op, log `warning`). `LiveEngagementEventsService` owns a separate `ModelContainer` for `PendingEngagementEvent` — engagement signals are per-device by design (no CloudKit). `ForYouCarouselView` embeds in `HomeView` and bubbles taps via `onArticleTapped` rather than owning navigation — same pattern as Home's other carousels.
32. **For You Settings is the only personalization UI surface** — reach via `Page.forYouSettings`. `ForYouSettingsDomainInteractor` actions: `loadProfile`, `removeTopic(topicID:)`, confirmed reset (`requestReset` → `confirmReset`/`cancelReset`). New personalization affordances belong here.
33. **Playback is a single global queue, not a per-screen player.** `Pulse/Playback/` owns one app-lifetime `PlaybackQueueService` (registered in `PulseSceneDelegate.registerLiveServices()`, VM held on `Coordinator.playbackViewModel`, rendered above every tab by `CoordinatorView`) wrapping the shared `TextToSpeechService`. `ArticleDetailDomainInteractor`'s "Listen" action and the Morning Briefing both enqueue into this same queue (`PlaybackMode.singleArticle` / `.briefing`) rather than owning their own TTS instance — never instantiate `TextToSpeechService`/`LiveTextToSpeechService` outside `LivePlaybackQueueService`. Morning Briefing itself is a **daily local notification** (`LiveNotificationService.scheduleMorningBriefingNotification`, `UNCalendarNotificationTrigger`, not `BGTaskScheduler` — timing isn't guaranteed) opening `pulse://briefing`; `MorningBriefingPrefetcher` opportunistically pre-generates the digest + a personalized For You queue on foreground activation so playback starts instantly, self-healing (cancels the notification) if Premium lapses while enabled. Gated by the existing `.dailyDigest` entitlement, not a separate premium check.
34. **Privacy conformance gates PR merges via deterministic code checks** in `.github/workflows/privacy-conformance.yml`, covering LGPD (Brazil, Lei 13.709/2018), GDPR (EU 2016/679), and CCPA/CPRA in one workflow (formerly two ~85%-identical files). Four jobs, on push/PR/weekly cron: **PII Scan** (CPF/CNPJ + US SSN regex bans, `.github/pii-allowlist.txt` email allowlist, gitleaks via `.github/lgpd-gdpr-rules.toml`), **Docs Presence** (README/AGENTS/CLAUDE/`PrivacyInfo.xcprivacy` non-empty, README mentions privacy), **Operational Controls** (`clearAllUserData` wired from sign-out + delete-account, env-var fallbacks `#if DEBUG`-gated, no plaintext `http://` in networking, CloudKit `.private(...)`, engagement container non-CloudKit), **Structural Integrity** (`Pulse/PrivacyInfo.xcprivacy` valid plist, every `NSPrivacyCollectedDataType` has a purpose, `*UsageDescription` strings non-empty). No PR-body marker, no AI review — deterministic checks only, since an AI verdict is rubber-stampable by prompt injection. New data-collecting SDKs need an `NSPrivacyCollectedDataTypes` entry; new email addresses need a `pii-allowlist.txt` entry (`@example.com`/`@test.com` wildcarded).
35. **Reviewer-only anonymous sign-in** — `SignInView`'s hidden 5-tap-on-logo gesture dispatches `.signInAnonymously` (Firebase Anonymous Auth) so App Review reaches auth-gated screens without shared OAuth credentials; documented in App Store Connect → App Review Information. A 60s throttle (UserDefaults `pulse.anonymousSignInLastAttempt`, set only on confirmed success, survives sign-out) rejects rapid re-taps with `AuthError.anonymousSignInThrottled`, which `AuthDomainInteractor` uses to suppress failed-`signIn` analytics/`recordError`; `PulseSceneDelegate.configureAnalyticsUserID()` sends `setUserID(nil)` for `provider == .anonymous`. The successful `signIn(provider: "anonymous")` event still logs (lets reviewer sessions be filtered from DAU/retention). Implementation in `LiveAuthService+Anonymous.swift` (split out to stay under the SwiftLint file-length budget). Never surface this gesture in onboarding, accessibility hints, or marketing — discoverability by real users is the only failure mode.
36. **Security review is threat-model-guided.** `THREAT_MODEL.md` (trust boundaries, untrusted inputs, vuln classes — backend out of scope, lives in `pulse-backend`) and `SEVERITY_RUBRIC.md` (Medium default ceiling — most flows sit behind Firebase auth + a private CloudKit zone) scope all security work. `.github/workflows/claude-security-review.yml` runs an **advisory** two-stage pass on PRs — `pr-discovery` (emits `security-findings.json`, posts nothing) → separate-context `pr-verify` (prompted to *disprove* each candidate, posts only confirmed), each stage clearing its own prior stale PR comments before posting fresh ones — plus a weekly full-repo sweep, distinct from `claude-code-review.yml` (which does the same self-cleanup). When you patch a validated finding, update `THREAT_MODEL.md` §3 and add a regression test (the deeplink sanitizer in rule 16 is the worked example). Keep these advisory, not in the required-check ruleset (that's reserved for the deterministic privacy gates in rule 34).

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
