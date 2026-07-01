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
│       ├── AI/                   # PromptSanitizer (untrusted-text → LLM prompt gate)
│       ├── Networking/           # APIKeys, Supabase, RemoteConfig, NetworkMonitor, SafeMediaURL
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

**Before changing code, check `AGENTS.md`** — it holds the full numbered rule set (concurrency, CloudKit, privacy CI, security review, Catalyst, sign-out wipe, anonymous sign-in, etc.) and is not preloaded here to save context. The two rules that crash the app if skipped:

- **Swift 6.2 concurrency** — every `.sink` in a `@MainActor` interactor mutating `stateSubject.value` **must** precede it with `.receive(on: DispatchQueue.main)` (services deliver off-main) or it crashes `_dispatch_assert_queue_fail`. `UncheckedSendableBox` / `WeakRef<T>` (in `CombineAsyncBridge.swift`) replace raw `Task` capture / `[weak self]` in `sending` closures.
- **Liquid Glass only** — `.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glassProminent)`. No legacy `.ultraThinMaterial`/`.regularMaterial` (narrow exceptions in AGENTS.md #21).

## Key Files

| Area | File | Purpose |
|------|------|---------|
| **Auth** | `LiveAuthService.swift`, `LiveAuthService+Anonymous.swift`, `AuthenticationManager.swift`, `RootView.swift`, `SignInView.swift` | Google/Apple sign-in, `deleteAccount(presenting:)` reauth; `+Anonymous` = reviewer-only path; auth-gated root |
| **Nav** | `Coordinator.swift`, `CoordinatorView.swift`, `SidebarContentView.swift`, `AdaptiveDetailStack.swift`, `Page.swift`, `DeeplinkRouter.swift` | Size-class adaptive root + tab paths |
| **Backend** | `SupabaseAPI.swift`, `SupabaseConfig.swift`, `SupabaseModels.swift` | REST endpoints, `?language=eq.<lang>` |
| **Cache/Offline** | `CachingNewsService.swift`, `CachingMediaService.swift`, `NewsCacheStore.swift`, `DiskNewsCacheStore.swift`, `NetworkResilience.swift`, `NetworkMonitorService.swift`, `PulseError.swift`, `OfflineBannerView.swift` | L1+L2 + resilience + offline banner |
| **Concurrency** | `CombineAsyncBridge.swift` | `UncheckedSendableBox`, `WeakRef` |
| **Localization** | `AppLocalization.swift`, `ContentLanguage.swift`, `{en,pt,es}.lproj/Localizable.strings` | `@MainActor` singleton, `nonisolated localized()` |
| **Storage** | `StorageService.swift`, `LiveStorageService.swift`, `ReadArticle.swift` | SwiftData + CloudKit private DB |
| **CloudSync** | `CloudSyncService.swift`, `LiveCloudSyncService.swift`, `CloudSyncDomainInteractor.swift`, `CloudSyncNotifications.swift` | Bridges CloudKit + `CKAccountChanged` into Combine |
| **LLM** | `LLMService.swift`, `LiveLLMService.swift`, `LLMModelManager.swift`, `LLMConfiguration.swift` | SwiftLlama, pinned thread + CFRunLoop, Metal 32 GPU layers |
| **StoreKit** | `StoreKitService.swift`, `LiveStoreKitService.swift`, `MockStoreKitService.swift`, `PremiumGateView.swift` (has `PremiumFeature` enum), `PaywallView.swift` | StoreKit 2; `MOCK_PREMIUM` env var for UI tests |
| **TTS** | `TextToSpeechService.swift`, `LiveTextToSpeechService.swift`, `SpeechPlayerBarView.swift` | `AVSpeechSynthesizer` + Now Playing + remote commands |
| **Live Activities** | `TTSActivityAttributes.swift`, `TTSLiveActivityController.swift`, `TTSLockScreenView.swift`, `PulseWidgetExtension/LiveActivities/TTSLiveActivity.swift` | Driven by `ArticleDetailDomainInteractor` |
| **Share Ext** | `PulseShareExtension/{ShareViewController,ShareRootView,SharedURLQueue}.swift`, `SharedURLImportService.swift`, `LiveSharedURLImportService.swift` | `public.url` → App Group queue → `pulse://shared` |
| **Intents / QA** | `Pulse/Intents/*.swift`, `PulseAppShortcuts.swift`, `QuickActionType.swift`, `QuickActionHandler.swift` | Route via `DeeplinkManager`; titles registered at scene-connect |
| **Analytics** | `AnalyticsService.swift`, `LiveAnalyticsService.swift`, `MockAnalyticsService.swift` | Firebase events + Crashlytics breadcrumbs |
| **Security** | `LiveAppLockService.swift`, `APIKeysProvider.swift`, `PromptSanitizer.swift` (`Configs/AI/`), `SafeMediaURL.swift` (`Configs/Networking/`), `PrivacyInfo.xcprivacy` | App lock; Keychain key storage; RSS→LLM prompt-injection gate; HTTPS-only media/article URL gate |
| **For You** | `ForYouDomainInteractor.swift`, `ForYouViewModel.swift`, `ForYouCarouselView.swift`, `ArticleScorer.swift`, `LiveForYouService.swift` | Personalized carousel in `HomeView`; on-device scoring |
| **Personalization** | `LiveTopicExtractionService.swift`, `LiveInterestProfileService.swift`, `LiveEngagementEventsService.swift`, `InterestTopicModel.swift`, `PendingEngagementEvent.swift`, `TopicExtractionDrainer.swift` | On-device topic extraction, interest profile, engagement signals (non-CloudKit container) |
| **For You Settings** | `ForYouSettingsDomainInteractor.swift`, `ForYouSettingsViewModel.swift`, `ForYouSettingsView.swift` | User controls for personalization |

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

Two independent providers:

- **NewsAPI / GNews keys** (`APIKeysProvider.swift`) — **Remote Config** (primary, min 10 chars) → **env vars** (`NEWS_API_KEY` / `GNEWS_API_KEY`, `#if DEBUG` only) → **Keychain** (user-provided). Release builds use Remote Config + Keychain only.
- **Supabase** (`SupabaseConfig.swift`) — only `SUPABASE_URL`, resolved **Remote Config** (non-empty check) → `SUPABASE_URL` **env var** (`#if DEBUG` only). No Keychain fallback and **no anon key** — the Edge Functions API is public/unauthenticated, so Release builds use Remote Config only.

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
