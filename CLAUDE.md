# Pulse — Claude Code Instructions

iOS news aggregation app. **Unidirectional Data Flow + Clean Architecture**, Combine reactive. Fetches from a self-hosted **Supabase** backend (Go RSS worker, `pulse-backend`).

## Architecture

```
View (SwiftUI, @ObservedObject)
  ↓ handle(event:)        ↑ @Published viewState
ViewModel (CombineViewModel)
  · EventActionMap: ViewEvent → DomainAction
  · Reducer: DomainState → ViewState
  ↓ dispatch(action:)     ↑ statePublisher
DomainInteractor (CombineInteractor)
  · CurrentValueSubject<DomainState, Never>
  ↓                       ↑
Service Layer (protocol + Live/Mock)
  ↓                       ↑
Network (EntropyCore) + Storage (SwiftData + CloudKit)
```

Core protocols from **`EntropyCore`**: `CombineViewModel`, `CombineInteractor`, `ViewStateReducing`, `DomainEventActionMap`, `ServiceLocator`. Design-system primitives (`Spacing`, `Typography`, `CornerRadius`, `HapticManager`, `Logger`) also come from EntropyCore — new files need `import EntropyCore`.

### DI: ServiceLocator

Registered once in `PulseSceneDelegate.registerLiveServices()` and passed by instance. Components take a single `ServiceLocator` in `init`. Tests register mocks on a fresh locator.

### Navigation: Coordinator + Router, size-class adaptive

- `CoordinatorView` swaps on `horizontalSizeClass`: compact → `AnimatedTabView`; regular → `NavigationSplitView { SidebarContentView } detail: { AdaptiveDetailStack }`.
- `@MainActor Coordinator` owns per-tab `NavigationPath`s, `selectedTab`, and `build(page:)`.
- Views are generic over their router: `HomeView<R: HomeNavigationRouter>`.
- `DeeplinkRouter` routes URL schemes through the `Coordinator`.

## Project Structure

```
Pulse/
├── Pulse/                        # app source
│   ├── Authentication/           # Firebase (Google + Apple), deleteAccount
│   ├── Home/  Media/  MediaDetail/  Search/  Settings/
│   ├── Feed/                     # AI Daily Digest (Premium)
│   ├── Digest/                   # On-device LLM (Gemma 3 1B via SwiftLlama)
│   ├── Summarization/            # Article summarization (Premium)
│   ├── ArticleDetail/            # Article + TTS + related articles
│   │   └── LiveActivities/       # TTSActivityAttributes, TTSLiveActivityController
│   ├── Intents/                  # AppIntents + PulseAppShortcuts
│   ├── QuickActions/             # Home-screen long-press shortcuts
│   ├── SharedURL/                # Drains Share Extension App Group queue
│   ├── Bookmarks/  ReadingHistory/
│   ├── ForYou/                   # Personalized carousel (embedded in Home)
│   ├── ForYouSettings/           # User controls for personalization
│   ├── Personalization/          # On-device topic extraction + engagement signals
│   ├── Notifications/  AppLock/  Onboarding/  Paywall/  SplashScreen/
│   ├── CloudSync/                # CloudKit lifecycle (no UI)
│   └── Configs/
│       ├── Navigation/           # Coordinator, Page, CoordinatorView, DeeplinkRouter
│       ├── DesignSystem/         # Liquid Glass components, DynamicTypeHelpers
│       ├── Models/               # Article, NewsCategory, AppLocalization
│       ├── Networking/           # APIKeys, Supabase, RemoteConfig, NetworkMonitor
│       ├── Storage/              # SwiftData + CloudKit private DB
│       ├── CloudSync/            # CloudSyncService
│       ├── Analytics/            # Firebase Analytics + Crashlytics
│       ├── Mocks/                # Mock services for tests
│       └── Widget/
├── PulseWidgetExtension/         # WidgetKit + TTSLiveActivity
├── PulseWidgetExtensionTests/
├── PulseShareExtension/          # public.url → SharedURLQueue
├── PulseTests/  PulseUITests/  PulseSnapshotTests/
├── Documentation.docc/           # DocC bundle
```

`ThemeManager` lives at `Pulse/Configs/ThemeManager.swift` (not in `DesignSystem/`).

## Critical Conventions

See **AGENTS.md** for the full rules list. The load-bearing ones:

- **Swift 6.2 strict concurrency.** Every `.sink` in a `@MainActor` interactor that mutates `stateSubject.value` **must** precede it with `.receive(on: DispatchQueue.main)` — services deliver on background queues; without this, state mutations crash with `_dispatch_assert_queue_fail`. Non-Sendable `Task` capture via `UncheckedSendableBox`; `WeakRef<T>` instead of `[weak self]` in `sending` closures (both in `CombineAsyncBridge.swift`).
- **Liquid Glass only** — `.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glassProminent)`. No legacy `.ultraThinMaterial` / `.regularMaterial`.
- **Localization** — `AppLocalization.shared.localized("key")`, not `String(localized:)`. Use `static var` computed (never `static let`) for localized constants so runtime language switches propagate.
- **Tiered cache** — `CachingNewsService` / `CachingMediaService` wrap Live services with L1 (NSCache, 10 min) + L2 (disk JSON, 24 h). Network fetches on cache miss use `Publisher.withNetworkResilience()` (2 retries, 1→2s backoff, 15s timeout). Stale L2 served when offline; pull-to-refresh clears L1 only.
- **CloudKit** — `ModelConfiguration(cloudKitDatabase: .private("iCloud.com.bruno.Pulse-News"))`. Syncs `BookmarkedArticle`, `ReadArticle`, `UserPreferencesModel`, `InterestTopicModel`. Every `@Model` property must have a default; no `@Attribute(.unique)` — uniqueness enforced in the service layer (fetch-before-upsert). `CloudSyncDomainInteractor` posts `.cloudSyncDidComplete`; Bookmarks / ReadingHistory / Settings / Home reload on it. `PendingEngagementEvent` (Personalization) lives in a **separate non-CloudKit container** — engagement signals stay per-device by design.
- **iPad layouts** — branch on `@Environment(\.horizontalSizeClass)`, not `userInterfaceIdiom` (Slide Over reports compact). Lists: `LazyVStack` (compact) vs `LazyVGrid(.adaptive(minimum: 360))` (regular). `ArticleDetailView` caps at 720pt. Card components take `cardWidth` from callers — never probe `UIApplication` for screen width.
- **System integrations** (App Intents, Quick Actions, Share Extension, push) route through `DeeplinkManager.shared.handle(deeplink:)`. All `AppIntent`s set `openAppWhenRun = true`.
- **Share Extension can't run the LLM** (Gemma 3 1B ≈ 600 MB ≫ extension's ~120 MB budget). It enqueues `SharedURLItem` to `SharedURLQueue` (App Group JSON) and opens `pulse://shared`; main app drains on foreground.
- **Mac Catalyst is OFF** (`SUPPORTS_MACCATALYST: false`) — vendored `swift-llama-cpp` xcframework has no Catalyst slice.
- **Sign-out and account deletion** call `SettingsViewModel.clearAllUserData()` — SwiftData + L1/L2 + keychain + UserDefaults + ThemeManager + widget data.
- **Reviewer-only anonymous sign-in** — `SignInView` has a hidden 5-tap-on-logo gesture that calls `Auth.auth().signInAnonymously()` so App Review reaches auth-gated screens without shared OAuth credentials (avoids 2FA friction). Trigger lives in App Store Connect → App Review Information; `AuthDomainInteractor` logs the analytics event as `provider: "anonymous"` for filtering. Implementation in `LiveAuthService+Anonymous.swift`.
- **Privacy conformance gates merges via deterministic code checks** (no PR-body marker required). `lgpd-conformance.yml` and `gdpr-conformance.yml` mirror the shape of the same-named workflows in `pulse-backend` — four parallel jobs each: **PII Scan** (CPF/CNPJ + US SSN regex bans, email allowlist in `.github/pii-allowlist.txt`, gitleaks with custom rules in `.github/lgpd-gdpr-rules.toml`), **Docs Presence** (README + AGENTS + CLAUDE + `Pulse/PrivacyInfo.xcprivacy` exist; README mentions privacy), **Operational Controls** (`SettingsViewModel.clearAllUserData()` is called from both sign-out + delete-account handlers, env-var API-key fallbacks are `#if DEBUG`-gated, no plaintext `http://` in `Pulse/Configs/Networking/`, `cloudKitDatabase: .private(...)`, engagement-events container is non-CloudKit), **Structural Integrity** (`PrivacyInfo.xcprivacy` is valid plist; every `NSPrivacyCollectedDataType` has a declared purpose; `*UsageDescription` strings in app + extension Info.plists are non-empty). Adding a new SDK that collects data needs a corresponding `NSPrivacyCollectedDataTypes` entry. New email addresses in source need an entry in `pii-allowlist.txt`.
- **Security review is threat-model-guided** (separate from the privacy gates above). `THREAT_MODEL.md` + `SEVERITY_RUBRIC.md` at repo root scope the trust boundaries, untrusted inputs (third-party RSS article JSON → on-device Gemma is the primary sink), vuln classes, and severity scoring (Medium default ceiling — most flows sit behind Firebase auth + a private CloudKit zone). `.github/workflows/claude-security-review.yml` runs an **advisory** adversarial security pass on PRs + a weekly sweep — distinct from the general `claude-code-review.yml`. Keep these advisory (not in the required-check ruleset); when you patch a validated finding, update `THREAT_MODEL.md` and add a regression test. Full rules: AGENTS.md #35.

## Key Files

| Area | File | Purpose |
|------|------|---------|
| **Auth** | `LiveAuthService.swift`, `LiveAuthService+Anonymous.swift` | Google/Apple sign-in, `deleteAccount(presenting:)` with `requiresRecentLogin` reauth; Firebase `User` calls wrapped in `withCheckedThrowingContinuation` (non-Sendable `User` never crosses `await`). `+Anonymous` extension is the reviewer-only Firebase Anonymous Auth path (5-tap on logo, hidden from real users). |
| | `AuthenticationManager.swift`, `RootView.swift`, `SignInView.swift` | Auth-gated root (SignIn / Onboarding / Coordinator) |
| **Nav** | `Coordinator.swift`, `CoordinatorView.swift`, `SidebarContentView.swift`, `AdaptiveDetailStack.swift`, `Page.swift`, `DeeplinkRouter.swift` | Size-class adaptive root + tab paths |
| **Backend** | `SupabaseAPI.swift`, `SupabaseConfig.swift`, `SupabaseModels.swift` | REST endpoints (language-filtered via `?language=eq.<lang>`) |
| **Cache/Offline** | `CachingNewsService.swift`, `CachingMediaService.swift`, `NewsCacheStore.swift`, `DiskNewsCacheStore.swift`, `NetworkResilience.swift`, `NetworkMonitorService.swift`, `PulseError.swift`, `OfflineBannerView.swift` | L1+L2 + resilience + offline banner |
| **Concurrency** | `CombineAsyncBridge.swift` | `UncheckedSendableBox`, `WeakRef` |
| **Localization** | `AppLocalization.swift`, `ContentLanguage.swift`, `{en,pt,es}.lproj/Localizable.strings` | `@MainActor` singleton, `nonisolated localized()` |
| **Storage** | `StorageService.swift`, `LiveStorageService.swift`, `ReadArticle.swift` | SwiftData + CloudKit private DB |
| **CloudSync** | `CloudSyncService.swift`, `LiveCloudSyncService.swift`, `CloudSyncDomainInteractor.swift`, `CloudSyncNotifications.swift` | Bridges `NSPersistentCloudKitContainer.eventChangedNotification` + `CKAccountChanged` into Combine |
| **LLM** | `LLMService.swift`, `LiveLLMService.swift`, `LLMModelManager.swift`, `LLMConfiguration.swift` | SwiftLlama; dedicated pinned thread + CFRunLoop (llama.cpp thread-local state); Metal 32 GPU layers |
| **StoreKit** | `StoreKitService.swift`, `LiveStoreKitService.swift`, `MockStoreKitService.swift`, `PremiumGateView.swift` (contains `PremiumFeature` enum), `PaywallView.swift` | StoreKit 2; `MOCK_PREMIUM` env var for UI tests |
| **TTS** | `TextToSpeechService.swift`, `LiveTextToSpeechService.swift`, `SpeechPlayerBarView.swift` | `AVSpeechSynthesizer` + `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` |
| **Live Activities** | `TTSActivityAttributes.swift`, `TTSLiveActivityController.swift`, `TTSLockScreenView.swift`, `PulseWidgetExtension/LiveActivities/TTSLiveActivity.swift` | Lock Screen + Dynamic Island; lifecycle driven by `ArticleDetailDomainInteractor` |
| **Share Ext** | `PulseShareExtension/{ShareViewController,ShareRootView,SharedURLQueue}.swift`, `SharedURLImportService.swift`, `LiveSharedURLImportService.swift` | `public.url` → App Group queue → `pulse://shared` |
| **Intents / QA** | `Pulse/Intents/*.swift`, `PulseAppShortcuts.swift`, `QuickActionType.swift`, `QuickActionHandler.swift` | All route via `DeeplinkManager`; QA titles localized (registered at scene-connect, not in `Info.plist`) |
| **Analytics** | `AnalyticsService.swift`, `LiveAnalyticsService.swift`, `MockAnalyticsService.swift` | Type-safe Firebase events (incl. CloudKit sync lifecycle); Crashlytics breadcrumbs |
| **Security** | `LiveAppLockService.swift`, `APIKeysProvider.swift` (Keychain storage for API keys), `PrivacyInfo.xcprivacy` | Biometric + passcode app lock; Keychain accessed inline via the `Security` framework |
| **For You** | `ForYouDomainInteractor.swift`, `ForYouViewModel.swift`, `ForYouCarouselView.swift`, `ArticleScorer.swift`, `LiveForYouService.swift` | Personalized carousel embedded in `HomeView`; on-device scoring against the interest profile |
| **Personalization** | `LiveTopicExtractionService.swift`, `LiveInterestProfileService.swift`, `LiveEngagementEventsService.swift`, `InterestTopicModel.swift`, `PendingEngagementEvent.swift`, `TopicExtractionDrainer.swift` | On-device LLM topic extraction, interest profile, engagement signals (separate non-CloudKit `ModelContainer`) |
| **For You Settings** | `ForYouSettingsDomainInteractor.swift`, `ForYouSettingsViewModel.swift`, `ForYouSettingsView.swift` | User controls for personalization (opt-in/out, topic editing) |

## Commands

```bash
make setup                              # install-xcodegen + generate
make build | build-release
make test | test-unit | test-ui | test-snapshot | test-debug
make lint | format
make coverage | coverage-report | coverage-badge
make deeplink-test | clean | clean-packages | docs
make bump-{patch,minor,major}
```

New source files require `make generate` (or `/setup`) to land in the Xcode project.

Slash commands: `/test*`, `/coverage`, `/build*`, `/run`, `/setup`, `/clean`, `/lint`, `/format`, `/fix-packages`, `/push`, `/reset`.

## API Keys

Resolution order: **Remote Config** (primary, min 10 chars) → **env vars** (`#if DEBUG` only) → **Keychain** (user-provided). `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Release builds use Remote Config + Keychain only. See `APIKeysProvider.swift`, `SupabaseConfig.swift`.

## Deeplinks

| URL | |
|---|---|
| `pulse://home` / `media` / `feed` / `bookmarks` / `search` / `settings` | tabs |
| `pulse://search?q=query` | search with query |
| `pulse://article?id=path/to/article` | specific article |
| `pulse://media?type=video` (or `podcast`) | media tab filtered by type |
| `pulse://shared` | drain Share Extension queue |
| `pulse://category?name=<category>` | **deprecated** — redirects to home tab |

**Push payloads:**
- `{"deeplink": "pulse://..."}` *(recommended)*
- `{"articleID": "world/2024/..."}` *(legacy shorthand)*
- `{"deeplinkType": "search|article|home|feed|bookmarks|settings", "deeplinkQuery": "...", "deeplinkId": "..."}`

## Troubleshooting

| Symptom | Fix |
|---|---|
| Build fails | `make clean && make generate` |
| Package resolution | `make clean-packages && make setup` |
| Test timeouts | check async waits in `.sink` / `Task.sleep` |
| Snapshot mismatch | re-record references; never lower precision |
| Service not found | verify `PulseSceneDelegate.registerLiveServices()` |
