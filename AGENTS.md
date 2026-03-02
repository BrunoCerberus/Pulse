# Pulse - Agent Guidelines

## Repository Overview

Pulse is an iOS news aggregation app built with **Unidirectional Data Flow Architecture** based on Clean Architecture principles, using **Combine** for reactive data binding. The app fetches news from a **Supabase backend** (primary) with **Guardian API** fallback. This document provides guidelines for AI agents and contributors working on the codebase.

## Project Structure

```
Pulse/
├── Pulse/                      # Main app source
│   ├── Authentication/         # Firebase Auth (Google + Apple Sign-In)
│   │   ├── API/                # AuthService protocol + Live/Mock implementations
│   │   ├── Domain/             # AuthDomainInteractor, State, Action
│   │   ├── ViewModel/          # SignInViewModel
│   │   ├── View/               # SignInView
│   │   └── Manager/            # AuthenticationManager (global state)
│   ├── Home/                   # Home feed with category filtering + recently read
│   ├── Media/                  # Videos and Podcasts browsing
│   │   ├── API/                # CachingMediaService (tiered cache decorator for LiveMediaService)
│   │   ├── Domain/             # MediaDomainInteractor, State, Action, Reducer, EventActionMap
│   │   ├── ViewModel/          # MediaViewModel
│   │   ├── View/               # MediaView, MediaCard, FeaturedMediaCard
│   │   └── Router/             # MediaNavigationRouter
│   ├── MediaDetail/            # Video/Podcast playback
│   │   ├── Domain/             # MediaDetailDomainInteractor, State, Action
│   │   ├── ViewModel/          # MediaDetailViewModel
│   │   ├── View/               # MediaDetailView, VideoPlayerView, AudioPlayerView, YouTubeThumbnailView
│   │   └── Player/             # AudioPlayerManager (AVPlayer wrapper)
│   ├── Feed/                   # AI-powered Daily Digest (Premium)
│   │   ├── API/                # FeedService protocol + Live/Mock
│   │   ├── Domain/             # FeedDomainInteractor, State, Action, Reducer, EventActionMap
│   │   ├── ViewModel/          # FeedViewModel
│   │   ├── View/               # FeedView, DigestCard, StreamingTextView, BentoGrid components
│   │   │   └── BentoGrid/      # BentoDigestGrid, StatsCard, TopicsBreakdownCard, ContentSectionCard
│   │   ├── ViewEvents/         # FeedViewEvent
│   │   ├── ViewStates/         # FeedViewState
│   │   ├── Router/             # FeedNavigationRouter
│   │   └── Models/             # DailyDigest, FeedDigestPromptBuilder
│   ├── Digest/                 # On-device LLM infra (LLMService, LLMModelManager, prompts)
│   │   ├── API/                # SummarizationService protocol + Live/Mock
│   │   ├── AI/                 # LLMService, LLMModelManager (llama.cpp via LocalLlama)
│   │   └── Models/             # Prompt builders and LLM helpers
│   ├── Summarization/          # Article summarization (Premium)
│   ├── ArticleDetail/          # Article view + summarization + text-to-speech + related articles
│   │   ├── API/                # TextToSpeechService protocol + Live/Mock implementations
│   │   ├── Domain/             # ArticleDetailDomainInteractor, State, Action, Reducer, EventActionMap
│   │   ├── ViewModel/          # ArticleDetailViewModel
│   │   ├── View/               # ArticleDetailView, SpeechPlayerBarView
│   │   └── ViewStates/         # ArticleDetailViewState
│   ├── Bookmarks/              # Offline reading
│   ├── ReadingHistory/         # Reading history tracking (SwiftData)
│   │   ├── Domain/             # ReadingHistoryDomainInteractor, State, Action
│   │   ├── ViewModel/          # ReadingHistoryViewModel
│   │   ├── View/               # ReadingHistoryView
│   │   └── Router/             # ReadingHistoryNavigationRouter
│   ├── Search/                 # Search feature
│   ├── Settings/               # User preferences (includes account/logout)
│   ├── AppLock/                # Biometric/passcode app lock (Keychain-backed)
│   ├── Onboarding/             # First-launch onboarding flow
│   ├── Paywall/                # StoreKit paywall UI
│   ├── SplashScreen/           # App launch animation
│   └── Configs/
│       ├── Navigation/         # Coordinator, Page, CoordinatorView, DeeplinkRouter, AnimatedTabView
│       ├── DesignSystem/       # ColorSystem, Typography, Components, DynamicTypeHelpers, Haptics
│       ├── Models/             # Article, NewsCategory, UserPreferences, ContentLanguage, AppLocalization
│       ├── Networking/         # API keys, base URLs, SupabaseConfig, RemoteConfig, NetworkMonitorService
│       ├── Storage/            # StorageService (SwiftData)
│       ├── Analytics/          # AnalyticsService protocol + Live implementation
│       ├── Mocks/              # Mock services for testing
│       └── Widget/             # WidgetDataManager + shared widget models
├── PulseWidgetExtension/       # WidgetKit extension
├── PulseTests/                 # Unit tests (Swift Testing)
├── PulseUITests/               # UI tests (XCTest)
├── PulseSnapshotTests/         # Snapshot tests (SnapshotTesting)
├── .github/workflows/          # CI/CD
└── .claude/commands/           # Claude slash commands
```

## Build & Test Commands

```bash
make init            # Setup Mint, SwiftFormat, and SwiftLint
make install-xcodegen # Install XcodeGen
make generate        # Generate project from project.yml
make setup           # install-xcodegen + generate
make xcode           # Generate project and open in Xcode
make build           # Debug build
make build-release   # Release build
make test            # Run all tests
make test-unit       # Run unit tests only
make test-ui         # Run UI tests only
make test-snapshot   # Run snapshot tests only
make test-debug      # Verbose unit tests
make lint            # Code quality checks
make format          # Auto-format code
make coverage        # Test with coverage
make coverage-report # Per-file coverage report
make coverage-badge  # Generate SVG coverage badge
make deeplink-test   # Deeplink tests
make clean           # Remove generated project
make clean-packages  # Clean SPM caches
make docs            # Generate DocC documentation
```

## Coding Style

### Naming Conventions
- **Types**: PascalCase (`HomeViewModel`, `ArticleViewItem`)
- **Functions/Variables**: camelCase (`fetchArticles`, `viewState`)
- **Protocols**: Descriptive names ending in `-ing`, `-able`, or `-Service`

### File Organization
```swift
// 1. Imports
import SwiftUI
import Combine

// 2. Type definition - ViewModel pattern
final class HomeViewModel: CombineViewModel, ObservableObject {
    // 3. Type aliases (required by CombineViewModel protocol)
    typealias ViewState = HomeViewState
    typealias ViewEvent = HomeViewEvent

    // 4. Published properties
    @Published private(set) var viewState: HomeViewState = .initial

    // 5. Private properties
    private let interactor: HomeDomainInteractor
    private let eventMap = HomeEventActionMap()
    private let reducer = HomeViewStateReducer()
    private var cancellables = Set<AnyCancellable>()

    // 6. Initializer
    init(interactor: HomeDomainInteractor) {
        self.interactor = interactor
        setupBindings()
    }

    // 7. Public methods (CombineViewModel protocol)
    func handle(event: HomeViewEvent) {
        guard let action = eventMap.map(event: event) else { return }
        interactor.dispatch(action: action)
    }

    // 8. Private methods - Combine bindings
    private func setupBindings() {
        interactor.statePublisher
            .map { [reducer] state in reducer.reduce(domainState: state) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
```

### SwiftUI Views
```swift
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    var body: some View {
        content
            .onAppear { viewModel.handle(event: .onAppear) }
    }

    @ViewBuilder
    private var content: some View { ... }
}
```

## Testing Guidelines

### Unit Tests (Swift Testing)
```swift
@Suite
@MainActor
struct HomeDomainInteractorTests {
    let mockNewsService: MockNewsService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: HomeDomainInteractor  // System Under Test

    init() {
        mockNewsService = MockNewsService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        // Wire mocks into locator
        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = HomeDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state is correct")
    func testInitialState() {
        #expect(sut.statePublisher.value == HomeDomainState.initial)
    }

    @Test("Load initial data updates state")
    func testLoadInitialData() async {
        // Arrange
        mockNewsService.breakingNewsResult = .success([Article.mock()])

        // Act
        sut.dispatch(action: .loadInitialData)

        // Assert - wait for Combine pipeline
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(!sut.statePublisher.value.isLoading)
    }
}
```

### Mock Services
- All services have mock implementations in `Configs/Mocks/`
- Create fresh ServiceLocator per test (not shared)
- Mocks expose `Result` properties for controlling success/failure paths

## Architecture Rules

1. **Unidirectional Data Flow**: Data flows in one direction through the layers
2. **Views never directly access Services** - always through ViewModels
3. **ViewModels never directly access APIs** - always through Interactors
4. **Domain layer is UI-agnostic** - no SwiftUI imports
5. **All dependencies injected via ServiceLocator**
6. **State is immutable** - use Equatable structs for DomainState and ViewState
7. **Authentication is required** - RootView gates access via AuthenticationManager
8. **AuthenticationManager is a singleton** - observed by RootView to switch between SignInView, OnboardingView, and CoordinatorView
9. **Onboarding is shown once** - After first sign-in, a 4-page onboarding flow is shown; completion is persisted via `@AppStorage("pulse.hasCompletedOnboarding")` + `OnboardingService`
10. **Premium features are gated** - AI features require subscription (checked via StoreKitService)
11. **Service decorators for cross-cutting concerns** - Use Decorator Pattern for caching, logging (e.g., `CachingNewsService` wraps `LiveNewsService`)
12. **Graceful fallback for data sources** - Live services (NewsService, SearchService) use Supabase as primary and fall back to Guardian API when not configured or on error
13. **Offline resilience** - Tiered cache (L1 memory + L2 disk) preserves content when offline; `NetworkMonitorService` tracks connectivity; failed refreshes keep existing data visible
14. **Analytics is optional** - `try? serviceLocator.retrieve(AnalyticsService.self)` ensures missing analytics never crashes the app; every analytics event doubles as a Crashlytics breadcrumb
15. **Language parameter threading** - All service protocols, cache keys, and interactors accept a `language` parameter (from `UserPreferences.preferredLanguage`). Supabase queries filter with `?language=eq.<lang>`. Cache keys include language prefix to prevent cross-language pollution. Interactors listen for `.userPreferencesDidChange` to reload on language switch.
16. **In-app localization** - Use `AppLocalization.shared.localized("key")` for all UI strings (NOT `String(localized:)`). The singleton is `@MainActor` but `localized()` is `nonisolated`. Use `static var` computed properties (not `static let`) for localized constants so they re-evaluate on language change.
17. **Dynamic Type adaptation** - Views with horizontal layouts must use `@Environment(\.dynamicTypeSize)` and switch to vertical stacking at accessibility sizes (`.accessibility1`+) via `DynamicTypeSize.isAccessibilitySize`. Increase `lineLimit` values at accessibility sizes.
18. **VoiceOver semantics** - Section/screen titles must have `.accessibilityAddTraits(.isHeader)`. Use `@AccessibilityFocusState` for focus management after async operations. Post `AccessibilityNotification.Announcement` for state changes (refresh complete, search results, errors).
19. **Input validation at boundaries** - Validate YouTube video IDs with strict regex before HTML interpolation. Sanitize deeplink IDs with character allowlists and path traversal rejection. Allowlist URL schemes (HTTPS only) before `UIApplication.shared.open()`. Sanitize disk cache filenames. Limit search queries to 256 characters.
20. **Sign-out clears all user data** - On sign-out, `SettingsViewModel.clearUserDataOnSignOut()` wipes SwiftData (bookmarks, preferences, reading history), L1+L2 caches, app lock keychain, recent searches, UserDefaults, ThemeManager, and widget shared data. Never leave stale user data after sign-out.
21. **Environment variable fallbacks are DEBUG-only** - API key fallbacks via `ProcessInfo.processInfo.environment` are wrapped in `#if DEBUG`. Release builds only use Remote Config and Keychain. Remote Config values are validated for minimum length (10+ chars).

## Data Source Architecture

The app uses a two-tier data source strategy:

| Source | Type | Description |
|--------|------|-------------|
| Supabase Backend | Primary | Self-hosted RSS aggregator with og:image and content extraction |
| Guardian API | Fallback | Direct API access when Supabase is not configured |

## Caching & Offline Architecture

The app uses a tiered cache with offline resilience:

| Layer | Implementation | TTL | Survives App Kill |
|-------|---------------|-----|-------------------|
| L1 (Memory) | `LiveNewsCacheStore` (NSCache) | 10 minutes | No |
| L2 (Disk) | `DiskNewsCacheStore` (JSON in Caches/) | 24 hours | Yes |

### Key Components

| Component | Purpose |
|-----------|---------|
| `CachingNewsService` | Decorator wrapping `LiveNewsService` with `fetchWithTieredCache()` - L1 → L2 → network with stale fallback |
| `CachingMediaService` | Decorator wrapping `LiveMediaService` with same tiered cache pattern for media endpoints |
| `DiskNewsCacheStore` | Persistent file-based cache implementing `NewsCacheStore` protocol |
| `NetworkMonitorService` | Protocol + Live (`NWPathMonitor`) + Mock for connectivity tracking |
| `PulseError` | Typed error enum with `.offlineNoCache` case |
| `OfflineBannerView` | Animated banner in `CoordinatorView` shown when offline |
| **Localization** | |
| `AppLocalization` | `@MainActor` singleton with `@Published language`; `nonisolated func localized(_:)` for cross-thread access; loads from `.lproj` bundles matching `ContentLanguage` |
| `ContentLanguage` | Enum (en/pt/es) with display names and flags for language picker |
| `Localizable.strings` | UI strings in `en.lproj/`, `pt.lproj/`, `es.lproj/` (90+ keys including accessibility announcements) |
| **Reading History** | |
| `ReadArticle` | SwiftData `@Model` with `@Attribute(.unique)` on `articleID`; stores title, URL, image, `readAt` timestamp |
| `ReadingHistoryDomainInteractor` | Loads/clears history via `StorageService`, publishes `.readingHistoryDidClear` notification |
| **Engagement** | |
| `ShareItemsBuilder` | Utility formatting share content as `[title — source, URL]` for richer social previews |
| `ReadingHistoryView` | History list with article cards, empty state, clear confirmation dialog |
| **Accessibility** | |
| `DynamicTypeHelpers` | `DynamicTypeSize.isAccessibilitySize` extension (`.accessibility1`+) used across 12 components |
| **Security** | |
| `LiveAppLockService` | Keychain-backed app lock with `deviceOwnerAuthentication` (biometric + passcode fallback) |
| `KeychainStore` | Protocol for Keychain access; production uses `KeychainManager`, tests use in-memory implementation |
| **Analytics & Crashlytics** | |
| `AnalyticsService` | Protocol with `logEvent`, `setUserID`, `recordError`, `log` |
| `AnalyticsEvent` | Type-safe enum with 21 events (screen views, article actions, TTS, purchases, auth, onboarding, etc.) |
| `LiveAnalyticsService` | Firebase Analytics + Crashlytics (events + breadcrumbs, disabled in DEBUG) |
| `MockAnalyticsService` | Records all events/errors in arrays for test assertions |
| **Text-to-Speech** | |
| `TextToSpeechService` | Protocol with `speak(text:language:rate:)`, `pause()`, `resume()`, `stop()` + Combine publishers for playback state and progress |
| `LiveTextToSpeechService` | `AVSpeechSynthesizer` wrapper with delegate-based progress, `.playback`/`.spokenAudio` audio session, language mapping (en→en-US, pt→pt-BR, es→es-ES) |
| `MockTextToSpeechService` | Call tracking + test helpers (`simulateProgress()`, `simulateFinished()`) |
| `SpeechPlayerBarView` | Floating mini-player bar with progress, play/pause, speed preset cycling (1x/1.25x/1.5x/2x), close button |
| `TTSPlaybackState` | Enum: `.idle`, `.playing`, `.paused` |
| `TTSSpeedPreset` | Enum: `.normal`, `.fast`, `.faster`, `.fastest` with `rate` and `next()` cycling |

### Offline Behavior
- **Stale data served when offline**: L1 or L2 cache returned even if expired
- **Content preserved on refresh failure**: Pull-to-refresh does not clear existing headlines/breaking news/media
- **Offline error differentiation**: Domain states expose `isOfflineError: Bool` for offline-specific error views
- **Cache invalidation is L1-only**: Pull-to-refresh clears memory cache; disk cache preserved as fallback

### Backend Features (pulse-backend)
- Aggregates RSS feeds from Guardian, BBC, TechCrunch, Science Daily, etc.
- Extracts high-resolution `og:image` from article pages
- Extracts full article content using go-readability
- Automatic article cleanup (configurable retention period)

### Article Model
```swift
struct Article {
    let imageURL: String?      // High-res og:image from backend
    let thumbnailURL: String?  // RSS feed image (smaller)
    let mediaType: MediaType?
    let mediaURL: String?

    // Prefer YouTube thumbnail, then full image, then thumbnail, then source favicon.
    var heroImageURL: String? { ... }
    // Prefer YouTube thumbnail, then thumbnail, then full image, then source favicon.
    var displayImageURL: String? { ... }
}
```

## Premium Feature Gating

Two AI-powered features are gated behind a premium subscription:

| Feature | Location | Non-Premium Behavior |
|---------|----------|---------------------|
| AI Daily Digest | Feed tab | Shows `PremiumGateView` |
| Article Summarization | Article detail toolbar | Shows paywall sheet |

### Implementation Pattern

Views that gate premium features follow this pattern:

```swift
struct FeedView<R: FeedNavigationRouter>: View {
    private let serviceLocator: ServiceLocator
    @State private var isPremium = false
    @State private var subscriptionCancellable: AnyCancellable?

    var body: some View {
        Group {
            if isPremium {
                premiumContent
            } else {
                PremiumGateView(feature: .dailyDigest, serviceLocator: serviceLocator)
            }
        }
        .onAppear {
            observeSubscriptionStatus()
        }
    }

    private func observeSubscriptionStatus() {
        subscriptionCancellable?.cancel()
        guard let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) else { return }
        isPremium = storeKitService.isPremium
        subscriptionCancellable = storeKitService.subscriptionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { newStatus in
                self.isPremium = newStatus  // Note: No [weak self] needed for struct views
            }
    }
}
```

### Testing Premium Features

- **Unit tests**: Use `MockStoreKitService(isPremium: true/false)`
- **UI tests**: Set `MOCK_PREMIUM=1` in launch environment for premium user tests
- **Snapshot tests**: Register `MockStoreKitService` in test ServiceLocator

## On-Device AI (Digest + Summarization)

The Digest feature uses **Llama 3.2 1B Instruct** (Q4_K_M quantization, ~700MB GGUF) for on-device inference:

| Component | Purpose |
|-----------|---------|
| `LocalLlama` | Local Swift package wrapping llama.cpp b5046 XCFramework |
| `SwiftLlama` | Thread-safe wrapper using dedicated pinned Thread + CFRunLoop |
| `LlamaModel` | Low-level llama.cpp bindings with vocab-based API |
| `LLMService` | Protocol for model load/unload/generate operations |
| `LLMModelManager` | Singleton managing model lifecycle and memory pressure |

### Threading Model
All llama.cpp operations run on a **dedicated pinned thread** (not just serialized) because llama.cpp uses thread-local state. The `SwiftLlama` class uses `CFRunLoop` to ensure the exact same OS thread handles all inference calls.

### Memory Management
- Model requires ~700MB RAM when loaded
- `LLMModelManager` checks available memory before loading
- Auto-unloads on `UIApplication.didReceiveMemoryWarningNotification`

### Performance Optimizations
- **Metal acceleration**: On device, llama.cpp offloads up to 32 layers to GPU (`n_gpu_layers = 32`); simulator stays CPU-only
- **Flash attention**: Enabled for faster KV cache operations
- **Memory mapping**: Model loaded via mmap for faster startup
- **Model preloading**: Triggered at app launch for premium users (`PulseSceneDelegate.preloadLLMModelIfPremium()`)

## Navigation Architecture

Pulse uses a **Coordinator + Router** pattern with per-tab NavigationPaths:

```
CoordinatorView (@StateObject Coordinator)
       │
   TabView (selection: $coordinator.selectedTab)
       │
   ┌───┴───┬──────┬──────┬─────────┬───────┐
 Home   Media   Feed   Bookmarks  Search
   │        │       │           │         │
NavigationStack(path: $coordinator.homePath)
       │
.navigationDestination(for: Page.self)
       │
coordinator.build(page:)
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `RootView` | Auth-gated root (shows SignInView, OnboardingView, or CoordinatorView) |
| `AuthenticationManager` | Global singleton observing Firebase auth state |
| `AuthService` | Protocol for sign-in/sign-out operations |
| `Page` | Enum of all navigable destinations |
| `Coordinator` | Central navigation manager with per-tab paths |
| `CoordinatorView` | Root view hosting TabView + NavigationStacks |
| `DeeplinkRouter` | Routes deeplinks to coordinator actions |
| `*NavigationRouter` | Feature-specific routers conforming to `NavigationRouter` |

### View Pattern
Views are generic over their router type for testability:
```swift
struct HomeView<R: HomeNavigationRouter>: View {
    private var router: R
    @ObservedObject var viewModel: HomeViewModel

    init(router: R, viewModel: HomeViewModel) {
        self.router = router
        self.viewModel = viewModel
    }
}
```

### Router Pattern
Routers conform to `NavigationRouter` from EntropyCore:
```swift
@MainActor
final class HomeNavigationRouter: NavigationRouter {
    private weak var coordinator: Coordinator?

    func route(navigationEvent: HomeNavigationEvent) {
        switch navigationEvent {
        case .articleDetail(let article):
            coordinator?.push(page: .articleDetail(article))
        case .settings:
            coordinator?.push(page: .settings)
        }
    }
}
```

### Deeplinks

| Deeplink | Description | Status |
|----------|-------------|--------|
| `pulse://home` | Open home tab | ✅ Full |
| `pulse://media` | Open Media tab (Videos & Podcasts) | ✅ Full |
| `pulse://feed` | Open Feed tab (AI Daily Digest) | ✅ Full |
| `pulse://bookmarks` | Open bookmarks tab | ✅ Full |
| `pulse://search` | Open search tab | ✅ Full |
| `pulse://search?q=query` | Search with query | ✅ Full |
| `pulse://settings` | Open settings (pushes onto Home) | ✅ Full |
| `pulse://article?id=path/to/article` | Open specific article by Guardian content ID | ✅ Full |

## Unidirectional Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│  User Interaction (tap, scroll, etc.)                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  View.handle(event: ViewEvent)                              │
│  - HomeView calls viewModel.handle(event: .onAppear)        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  ViewModel.handle(event:)                                   │
│  - EventActionMap.map(event:) → DomainAction                │
│  - interactor.dispatch(action:)                             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Interactor.dispatch(action:)                               │
│  - Executes business logic                                  │
│  - Calls services (NewsService, StorageService, etc.)       │
│  - Updates DomainState via CurrentValueSubject              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  statePublisher emits new DomainState                       │
│  - ViewModel subscribes via Combine                         │
│  - ViewStateReducer.reduce(domainState:) → ViewState        │
│  - Assigns to @Published viewState                          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  View re-renders with new ViewState                         │
│  - SwiftUI observes @Published changes                      │
│  - UI updates reactively                                    │
└─────────────────────────────────────────────────────────────┘
```

### Key Protocols

| Protocol | Purpose | Location |
|----------|---------|----------|
| `CombineViewModel` | Base for ViewModels with `viewState` and `handle(event:)` | `EntropyCore` |
| `CombineInteractor` | Base for Interactors with `statePublisher` and `dispatch(action:)` | `EntropyCore` |
| `ViewStateReducing` | Transforms DomainState → ViewState | `EntropyCore` |
| `DomainEventActionMap` | Maps ViewEvent → DomainAction | `EntropyCore` |
| `ServiceLocator` | Dependency injection container | `EntropyCore` |

## Commit Guidelines

Use Conventional Commits:
```
feat: add article sharing
fix: resolve bookmark persistence issue
test: add settings view model tests
docs: update architecture diagram
refactor: extract common loading state
```

## PR Guidelines

1. **Title**: Clear, concise description
2. **Description**: What changed and why
3. **Testing**: List manual test steps
4. **Screenshots**: For UI changes

## Common Tasks

### Adding a New Feature
1. Create feature folder with standard structure
2. Define Service protocol and Live implementation
3. Create Domain layer (State, Action, Interactor)
4. Create ViewModel with ViewStateReducer
5. Create SwiftUI View
6. Register service in `PulseSceneDelegate.registerLiveServices()` (and add a mock in test setup)
7. Add unit tests
8. Add snapshot tests

### Adding a New API Endpoint
1. Add case to appropriate API enum
2. Implement in Live service
3. Add mock implementation
4. Test with unit tests

### Modifying UI
1. Update ViewState if needed
2. Modify View
3. If adding horizontal layouts, add Dynamic Type adaptation (`@Environment(\.dynamicTypeSize)`)
4. Add `.accessibilityAddTraits(.isHeader)` to section titles
5. Update/add snapshot tests (including accessibility size configs)
6. Test on multiple screen sizes

## API Keys

API keys are managed via **Firebase Remote Config** (primary) with fallbacks:

| Priority | Source | Purpose |
|----------|--------|---------|
| 1 | Remote Config | Primary source, fetched on app launch (validated for min 10 chars) |
| 2 | Environment variables | **DEBUG builds only** — local development |
| 3 | Keychain | Runtime storage for user-provided keys |

```bash
# Environment variable fallback (DEBUG builds only)
GUARDIAN_API_KEY      # Guardian API key (fallback data source)
NEWS_API_KEY          # NewsAPI.org key (wired in APIKeysProvider)
GNEWS_API_KEY         # GNews API key (wired in APIKeysProvider)
SUPABASE_URL          # Supabase project URL (primary data source)
SUPABASE_ANON_KEY     # Supabase anonymous key
```

See `Configs/Networking/APIKeysProvider.swift` and `SupabaseConfig.swift` for implementation. Environment variable fallbacks are gated behind `#if DEBUG`. If Supabase is not configured, the app automatically falls back to the Guardian API.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails | `make clean && make generate` |
| Tests timeout | Check async test waits |
| Snapshot mismatch | Run with `record: true` to update |
| Service not found | Verify ServiceLocator registration |
