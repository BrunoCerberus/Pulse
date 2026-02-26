# Pulse - Claude Code Instructions

## Project Overview

Pulse is an iOS news aggregation app built with **Unidirectional Data Flow Architecture** based on Clean Architecture principles, using **Combine** for reactive data binding. The app fetches news from a **Supabase backend** (primary) powered by a Go RSS worker, with **Guardian API** fallback.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  View (SwiftUI)                                             │
│  @ObservedObject viewModel                                  │
└─────────────────────────────────────────────────────────────┘
       │ handle(event: ViewEvent)           ↑ @Published viewState
       ↓                                    │
┌─────────────────────────────────────────────────────────────┐
│  ViewModel (CombineViewModel)                               │
│  - EventActionMap: ViewEvent → DomainAction                 │
│  - Reducer: DomainState → ViewState                         │
└─────────────────────────────────────────────────────────────┘
       │ dispatch(action:)                  ↑ statePublisher
       ↓                                    │
┌─────────────────────────────────────────────────────────────┐
│  DomainInteractor (CombineInteractor)                       │
│  - CurrentValueSubject<DomainState, Never>                  │
│  - Business logic + state mutations                         │
└─────────────────────────────────────────────────────────────┘
       │                                    ↑
       ↓                                    │
┌─────────────────────────────────────────────────────────────┐
│  Service Layer (Protocol-based)                             │
│  - Live implementations for production                      │
│  - Mock implementations for testing                         │
└─────────────────────────────────────────────────────────────┘
       │                                    ↑
       ↓                                    │
┌─────────────────────────────────────────────────────────────┐
│  Network Layer (EntropyCore) + Storage (SwiftData)          │
└─────────────────────────────────────────────────────────────┘
```

### Key Patterns

1. **Unidirectional Data Flow**: Reactive Combine-based architecture
   - **View Layer**: SwiftUI views with `@ObservedObject` ViewModels
   - **Presentation Layer**: ViewModels implementing `CombineViewModel`
   - **Domain Layer**: Interactors implementing `CombineInteractor`
   - **Service Layer**: Protocol-based services with Live/Mock implementations

2. **Core Protocols** (from `EntropyCore` package):
   ```swift
   // ViewModel protocol
   protocol CombineViewModel: ObservableObject {
       associatedtype ViewState: Equatable
       associatedtype ViewEvent
       var viewState: ViewState { get }
       func handle(event: ViewEvent)
   }

   // Interactor protocol
   protocol CombineInteractor {
       associatedtype DomainState: Equatable
       associatedtype DomainAction
       var statePublisher: AnyPublisher<DomainState, Never> { get }
       func dispatch(action: DomainAction)
   }

   // State transformation
   protocol ViewStateReducing {
       associatedtype DomainState
       associatedtype ViewState
       func reduce(domainState: DomainState) -> ViewState
   }

   // Event to action mapping
   protocol DomainEventActionMap {
       associatedtype ViewEvent
       associatedtype DomainAction
       func map(event: ViewEvent) -> DomainAction?
   }
   ```

3. **ServiceLocator**: Instance-based dependency injection (passed through initializers)
   ```swift
   // Service Registration (PulseSceneDelegate.registerLiveServices())
   let serviceLocator = ServiceLocator()
   serviceLocator.register(NewsService.self, instance: CachingNewsService(wrapping: LiveNewsService()))
   serviceLocator.register(StorageService.self, instance: LiveStorageService())

   // Component Initialization
   class HomeDomainInteractor {
       init(serviceLocator: ServiceLocator) {
           self.newsService = try serviceLocator.retrieve(NewsService.self)
       }
   }

   // Test Setup
   private func createTestServiceLocator() -> ServiceLocator {
       let serviceLocator = ServiceLocator()
       serviceLocator.register(NewsService.self, instance: MockNewsService())
       return serviceLocator
   }
   ```

   **Key Benefits:**
   - **Single Dependency**: Components only accept ServiceLocator as constructor parameter
   - **Centralized Registration**: All services registered in one place (PulseSceneDelegate)
   - **Easy Testing**: Mock services automatically injected in test environments
   - **Type Safety**: Compile-time service resolution with proper error handling

4. **Coordinator + Router Navigation**: Centralized navigation with per-tab paths

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

   ```swift
   // Coordinator manages all navigation paths
   @MainActor
   final class Coordinator: ObservableObject {
       @Published var selectedTab: AppTab = .home
       @Published var homePath = NavigationPath()
       // ... other tab paths

       func push(page: Page, in tab: AppTab? = nil) { ... }
       func pop() { ... }
       func popToRoot(in tab: AppTab? = nil) { ... }
   }

   // Views are generic over router type
   struct HomeView<R: HomeNavigationRouter>: View {
       private var router: R
       @ObservedObject var viewModel: HomeViewModel
   }

   // Routers conform to NavigationRouter from EntropyCore
   @MainActor
   final class HomeNavigationRouter: NavigationRouter {
       func route(navigationEvent: HomeNavigationEvent) { ... }
   }
   ```

   **Key Benefits:**
   - **Isolated Tab Navigation**: Each tab has its own NavigationPath
   - **Type-Safe Routes**: Page enum defines all destinations
   - **Testable Views**: Generic router type allows mock injection
   - **Deeplink Support**: DeeplinkRouter coordinates with Coordinator

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
│   ├── Home/                   # Home feed with category filtering
│   ├── Media/                  # Videos and Podcasts browsing
│   ├── MediaDetail/            # Video/Podcast playback
│   ├── Feed/                   # AI-powered Daily Digest (Premium)
│   ├── Digest/                 # On-device LLM infra (LLMService, LLMModelManager, prompts)
│   ├── Summarization/          # Article summarization (Premium)
│   ├── ArticleDetail/          # Article view + summarization + text-to-speech
│   ├── Bookmarks/              # Offline reading
│   ├── ReadingHistory/         # Reading history tracking (SwiftData)
│   ├── Search/                 # Search feature
│   ├── Settings/               # User preferences (includes account/logout)
│   ├── AppLock/                # Biometric/passcode app lock (Keychain-backed)
│   ├── Onboarding/             # First-launch onboarding flow
│   ├── Paywall/                # StoreKit paywall UI
│   ├── SplashScreen/           # App launch animation
│   └── Configs/
│       ├── Navigation/         # Coordinator, Page, CoordinatorView, DeeplinkRouter, AnimatedTabView
│       ├── DesignSystem/       # ColorSystem, Typography, Components, DynamicTypeHelpers
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
└── .github/workflows/          # CI/CD
```

## Features

| Feature | Description |
|---------|-------------|
| **Authentication** | Firebase Auth with Google and Apple Sign-In (required before accessing app) |
| **Home** | Breaking news carousel, top headlines with infinite scroll, category tabs for filtering by followed topics, settings access via gear icon |
| **Media** | Browse and play Videos and Podcasts with in-app playback (YouTube videos open in YouTube app, podcasts use native AVPlayer) |
| **Feed** | AI-powered Daily Digest summarizing latest news articles from the API using on-device LLM (Llama 3.2-1B) (**Premium**) |
| **Article Summarization** | On-device AI article summarization via sparkles button (**Premium**) |
| **Text-to-Speech** | Listen to articles read aloud using native `AVSpeechSynthesizer` with play/pause, speed presets (1x/1.25x/1.5x/2x), language-aware voices, and floating mini-player bar |
| **Search** | Full-text search with 300ms debounce, suggestions, and sort options (last tab with liquid glass style) |
| **Offline Experience** | Tiered cache (L1 memory + L2 disk), NWPathMonitor network monitoring, offline banner, graceful degradation |
| **Bookmarks** | Save articles for offline reading (SwiftData) |
| **Reading History** | Automatic tracking of read articles (SwiftData `ReadArticle` model), visual indicators on cards (reduced opacity), dedicated history view from Settings |
| **Localization** | Multi-language support (English, Portuguese, Spanish) — both UI labels and content filtering follow in-app language preference via `AppLocalization` singleton (no app restart required) |
| **Accessibility** | Dynamic Type layout adaptation (HStack-to-VStack at accessibility sizes), VoiceOver heading hierarchy, `@AccessibilityFocusState` management, live announcements for async state changes |
| **Security** | YouTube video ID regex validation, deeplink ID sanitization (character allowlist + path traversal rejection), URL scheme allowlisting, disk cache filename sanitization, Keychain-based app lock with biometric + passcode fallback |
| **Settings** | Topics, notifications, theme, content language, muted content, reading history, account/logout (accessed from Home navigation bar) |
| **Onboarding** | 4-page first-launch experience (welcome, AI features, offline/bookmarks, get started) shown once after sign-in |
| **Analytics & Crashlytics** | Firebase Analytics (21 type-safe events) and Crashlytics for crash/non-fatal error tracking at DomainInteractor level |
| **Widget** | Home screen widget showing recent headlines (WidgetKit extension) |

## Premium Features

The app uses StoreKit 2 for subscription management. Two AI-powered features are gated behind premium:

| Feature | Gate Location | Description |
|---------|---------------|-------------|
| **AI Daily Digest** | Feed tab | Non-premium users see `PremiumGateView` instead of digest content |
| **Article Summarization** | Article detail toolbar | Non-premium users see paywall when tapping sparkles button |

### Key Components

| Component | Purpose |
|-----------|---------|
| `StoreKitService` | Protocol for subscription status (`isPremium`, `subscriptionStatusPublisher`) |
| `LiveStoreKitService` | StoreKit 2 implementation with native `SubscriptionStoreView` |
| `MockStoreKitService` | Mock for testing (supports `MOCK_PREMIUM` env var in UI tests) |
| `PremiumFeature` | Enum defining gated features with icons, colors, titles, descriptions |
| `PremiumGateView` | Reusable upsell component shown to non-premium users |
| `PaywallView` | Native StoreKit subscription UI (iOS 17+) |

### Premium Status Flow

```
View.onAppear
     ↓
StoreKitService.subscriptionStatusPublisher
     ↓
@State isPremium updated via Combine
     ↓
View conditionally shows:
  - Premium content (if isPremium == true)
  - PremiumGateView (if isPremium == false)
```

## Development Commands

```bash
# Setup
make init               # Setup Mint, SwiftFormat, and SwiftLint
make install-xcodegen   # Install XcodeGen using Homebrew
make generate           # Generate project from project.yml
make setup              # install-xcodegen + generate
make xcode              # Generate project + open in Xcode

# Building
make build              # Debug build
make build-release      # Release build

# Version Management
make bump-patch         # Increase patch version (0.0.x)
make bump-minor         # Increase minor version (0.x.0)
make bump-major         # Increase major version (x.0.0)

# Testing
make test               # All tests
make test-unit          # Unit tests only
make test-ui            # UI tests only
make test-snapshot      # Snapshot tests only
make test-debug         # Verbose unit test output

# Code Quality
make lint               # SwiftFormat + SwiftLint check
make format             # Auto-fix formatting

# Coverage
make coverage           # Run tests with coverage
make coverage-report    # Per-file coverage report
make coverage-badge     # Generate SVG badge

# Utilities
make deeplink-test      # Deeplink tests
make clean              # Remove generated Xcode project
make clean-packages     # Clean SPM caches
make docs               # Generate DocC documentation
```

## Custom Slash Commands

| Command | Description |
|---------|-------------|
| `/test` | Run full test suite |
| `/test-unit` | Run unit tests |
| `/test-ui` | Run UI tests |
| `/test-snapshot` | Run snapshot tests |
| `/test-debug` | Run tests with verbose output |
| `/coverage` | Generate coverage report |
| `/build` | Debug build |
| `/build-release` | Release build |
| `/run` | Build and open in Xcode |
| `/setup` | Install XcodeGen + generate project |
| `/clean` | Clean and regenerate project |
| `/lint` | Check code style (SwiftFormat + SwiftLint) |
| `/format` | Auto-fix formatting issues |
| `/fix-packages` | Fix SPM resolution issues |
| `/push` | Stage, commit, and push |
| `/reset` | Discard all changes (DESTRUCTIVE) |

## Network Layer (EntropyCore)

All Live services (LiveNewsService, LiveSearchService) use Supabase as the primary backend with Guardian API fallback.

### Supabase Backend (Primary)

```swift
enum SupabaseAPI: APIFetcher {
    case articles(language: String, page: Int, pageSize: Int)
    case articlesByCategory(language: String, category: String, page: Int, pageSize: Int)
    case breakingNews(language: String, limit: Int)
    case article(id: String)
    case search(query: String, page: Int, pageSize: Int)
    case categories
    case sources
    case media(language: String, type: String?, page: Int, pageSize: Int)
    case featuredMedia(language: String, type: String?, limit: Int)

    var path: String { ... }  // language cases append ?language=eq.<lang>
    var method: HTTPMethod { .GET }
}

final class LiveNewsService: APIRequest, NewsService {
    private let useSupabase: Bool

    override init() {
        self.useSupabase = SupabaseConfig.isConfigured
        super.init()
    }

    func fetchTopHeadlines(language: String, country: String, page: Int) -> AnyPublisher<[Article], Error> {
        if useSupabase {
            return fetchFromSupabase(language: language, page: page)
                .catch { [weak self] error -> AnyPublisher<[Article], Error> in
                    // Automatic fallback to Guardian on Supabase error
                    return self?.fetchFromGuardian(page: page) ?? Fail(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        return fetchFromGuardian(page: page)
    }
}
```

The Supabase backend is powered by a Go RSS worker (`pulse-backend`) that:
- Fetches articles from multiple RSS sources (Guardian, BBC, TechCrunch, etc.)
- Extracts `og:image` from article pages for high-resolution hero images
- Extracts full article content using go-readability (Mozilla Readability port)
- Stores in Supabase with automatic article cleanup

### Guardian API (Fallback)

```swift
enum GuardianAPI: APIFetcher {
    case search(query: String?, section: String?, page: Int, pageSize: Int, orderBy: String)
    case sections

    var path: String { ... }
    var method: HTTPMethod { .GET }
}
```

Guardian API is used as fallback when:
- Supabase is not configured (missing URL or API key)
- Supabase API returns an error

## Caching & Offline Layer

The app uses a two-tier caching strategy with offline resilience:

```swift
// CachingNewsService and CachingMediaService wrap live services with L1 (memory) + L2 (disk) caches
let networkMonitor = LiveNetworkMonitorService()
let cachingNewsService = CachingNewsService(wrapping: LiveNewsService(), networkMonitor: networkMonitor)
serviceLocator.register(NewsService.self, instance: cachingNewsService)
serviceLocator.register(MediaService.self, instance: CachingMediaService(wrapping: LiveMediaService(), networkMonitor: networkMonitor))
serviceLocator.register(NetworkMonitorService.self, instance: networkMonitor)
```

### Tiered Cache

| Layer | Implementation | TTL | Survives App Kill |
|-------|---------------|-----|-------------------|
| L1 (Memory) | `NSCache` via `LiveNewsCacheStore` | 10 minutes | No |
| L2 (Disk) | `DiskNewsCacheStore` (JSON files in `Caches/PulseNewsCache/`) | 24 hours | Yes |

### Fetch Flow (`fetchWithTieredCache`)

1. **L1 hit** (non-expired) → return immediately
2. **L2 hit** (non-expired) → promote to L1, return
3. **Offline**: serve stale data from L1 or L2; if nothing cached → `Fail(PulseError.offlineNoCache)`
4. **Online**: network fetch → write-through to L1 + L2; on failure → fall back to stale L2

### Cache Invalidation

Pull-to-refresh clears L1 (memory) only. Disk cache is preserved as an offline fallback:

```swift
// HomeDomainInteractor.refresh()
if let cachingService = newsService as? CachingNewsService {
    cachingService.invalidateCache()  // Clears L1 only, disk preserved
}
```

### Network Monitoring

`NetworkMonitorService` (protocol + `LiveNetworkMonitorService` + `MockNetworkMonitorService`) uses `NWPathMonitor` to track connectivity:
- `isConnected: Bool` property and `isConnectedPublisher: AnyPublisher<Bool, Never>`
- `CoordinatorView` subscribes to show/hide an animated `OfflineBannerView`
- Domain states expose `isOfflineError: Bool` for offline-specific error views
- Failed refreshes preserve existing cached content (headlines, breaking news, media) instead of clearing

## Testing Strategy

### Unit Tests (Swift Testing)
- Test DomainInteractors with mock services
- Test ViewModels with mock interactors
- Test ViewStateReducers

### UI Tests (XCTest)
- Navigation flows
- Tab bar interactions
- Search functionality
- iOS 17+ accessibility audits (`performAccessibilityAudit()`) on all main screens

### Snapshot Tests (SnapshotTesting)
- View components
- Loading states
- Empty states
- Dynamic Type accessibility snapshots (`iPhoneAirAccessibility`, `iPhoneAirExtraExtraLarge` configs)

## Key Files

| File | Purpose |
|------|---------|
| **Architecture Protocols (EntropyCore)** | |
| `CombineViewModel` | Base protocol for ViewModels |
| `CombineInteractor` | Base protocol for domain interactors |
| `ViewStateReducing` | Protocol for state transformation |
| `DomainEventActionMap` | Protocol for event-to-action mapping |
| `ServiceLocator` | Dependency injection container |
| **Authentication** | |
| `AuthService.swift` | Protocol for authentication operations |
| `LiveAuthService.swift` | Firebase Auth implementation (Google + Apple) |
| `AuthenticationManager.swift` | Global auth state observer singleton |
| `RootView.swift` | Auth-gated root view (SignIn vs Onboarding vs CoordinatorView) |
| `SignInView.swift` | Sign-in UI with Google/Apple buttons |
| **Navigation** | |
| `Coordinator.swift` | Central navigation manager with per-tab paths |
| `CoordinatorView.swift` | Root TabView with NavigationStacks |
| `Page.swift` | Enum of all navigable destinations |
| `DeeplinkRouter.swift` | Routes deeplinks to coordinator |
| `*NavigationRouter.swift` | Feature-specific navigation routers |
| **Infrastructure** | |
| `DeeplinkManager.swift` | URL scheme handling |
| `ThemeManager.swift` | Dark/light mode management |
| `StorageService.swift` | SwiftData persistence |
| `GuardianAPI.swift` | Guardian API endpoint definitions (fallback) |
| `NewsAPI.swift` | NewsAPI.org endpoint definitions (wired in APIKeysProvider) |
| `GoogleService-Info.plist` | Firebase configuration |
| **Supabase Backend** | |
| `SupabaseConfig.swift` | Supabase URL and API key configuration |
| `SupabaseAPI.swift` | Supabase REST API endpoint definitions (language-filtered) |
| `SupabaseModels.swift` | Supabase response models (SupabaseArticle, SupabaseSource, SupabaseCategory) |
| **Caching & Offline** | |
| `NewsCacheStore.swift` | Cache protocol, NSCache implementation (L1), TTL configuration |
| `DiskNewsCacheStore.swift` | Persistent file-based cache (L2) in Caches/PulseNewsCache/ |
| `CachingNewsService.swift` | Decorator wrapping LiveNewsService with tiered L1+L2 caching + offline awareness |
| `CachingMediaService.swift` | Decorator wrapping LiveMediaService with tiered L1+L2 caching + offline awareness |
| `NetworkMonitorService.swift` | Protocol + Live (NWPathMonitor) + Mock for connectivity monitoring |
| `PulseError.swift` | Typed error enum distinguishing offline from server errors |
| `OfflineBannerView.swift` | Animated offline banner shown at top of app when disconnected |
| **Localization** | |
| `AppLocalization.swift` | `@MainActor` singleton managing in-app language; `nonisolated func localized(_:)` for cross-thread access |
| `ContentLanguage.swift` | Enum (en/pt/es) with display names and flag emojis for language picker |
| `en.lproj/Localizable.strings` | English UI strings (90+ keys including accessibility announcements) |
| `pt.lproj/Localizable.strings` | Portuguese UI translations |
| `es.lproj/Localizable.strings` | Spanish UI translations |
| **Reading History** | |
| `ReadArticle.swift` | SwiftData `@Model` with `@Attribute(.unique)` on `articleID`, stores read timestamp |
| `ReadingHistoryDomainInteractor.swift` | Loads/clears history via `StorageService`, publishes `.readingHistoryDidClear` notification |
| `ReadingHistoryView.swift` | History list with article cards, empty state, clear confirmation dialog |
| **Accessibility** | |
| `DynamicTypeHelpers.swift` | `DynamicTypeSize.isAccessibilitySize` extension (`.accessibility1`+) |
| **Security** | |
| `LiveAppLockService.swift` | Keychain-backed app lock with `deviceOwnerAuthentication` policy (biometric + passcode) |
| `KeychainStore.swift` | Protocol for Keychain access (testable with in-memory implementation) |
| **Widget** | |
| `WidgetDataManager.swift` | Persists shared widget articles and triggers WidgetKit reloads |
| **Media Playback** | |
| `MediaDetailView.swift` | Main view for video/podcast playback |
| `VideoPlayerView.swift` | WKWebView wrapper for non-YouTube video embedding |
| `YouTubeThumbnailView.swift` | YouTube thumbnail with "Watch on YouTube" button (opens externally) |
| `AudioPlayerView.swift` | AVPlayer-based podcast player with custom controls |
| `AudioPlayerManager.swift` | AVPlayer wrapper managing playback state and time observation |
| **AI/LLM** | |
| `LLMService.swift` | Protocol for LLM operations (load, generate, cancel) |
| `LiveLLMService.swift` | LEAP SDK implementation for on-device LLM inference |
| `LLMModelManager.swift` | Model lifecycle (load/unload, memory checks) |
| `LLMConfiguration.swift` | Model paths, inference parameters (context size, batch size) |
| **LLM Performance** | Metal acceleration on device, flash attention, mmap loading, model preloading |
| **Premium/Subscription** | |
| `StoreKitService.swift` | Protocol for subscription status and purchases |
| `LiveStoreKitService.swift` | StoreKit 2 implementation |
| `MockStoreKitService.swift` | Mock for testing (respects `MOCK_PREMIUM` env var) |
| `PremiumGateView.swift` | Reusable premium upsell component |
| `PremiumFeature.swift` | Enum defining gated features |
| `PaywallView.swift` | Native StoreKit subscription UI |
| **Text-to-Speech** | |
| `TextToSpeechService.swift` | Protocol + `TTSPlaybackState` enum + `TTSSpeedPreset` enum (1x/1.25x/1.5x/2x) |
| `LiveTextToSpeechService.swift` | `AVSpeechSynthesizer` wrapper with delegate-based progress tracking and language-aware voices |
| `MockTextToSpeechService.swift` | Mock with call tracking (`speakCallCount`, `lastSpokenText`, etc.) and test helpers (`simulateProgress`, `simulateFinished`) |
| `SpeechPlayerBarView.swift` | Floating mini-player bar with progress, play/pause, speed preset, and close buttons |
| **Onboarding** | |
| `OnboardingService.swift` | Protocol with `hasCompletedOnboarding: Bool` |
| `LiveOnboardingService.swift` | UserDefaults-backed implementation (key: `pulse.hasCompletedOnboarding`) |
| `OnboardingPage.swift` | Enum with 4 cases: welcome, aiPowered, stayConnected, getStarted |
| `OnboardingDomainInteractor.swift` | Page navigation, completion persistence, analytics logging |
| `OnboardingView.swift` | Main view with TabView(.page), custom dots, Skip/Next buttons |
| **Analytics & Crashlytics** | |
| `AnalyticsService.swift` | Protocol + `AnalyticsEvent` enum (21 events) + `AnalyticsScreen`/`AnalyticsSource` enums |
| `LiveAnalyticsService.swift` | Firebase Analytics + Crashlytics implementation (events + breadcrumbs) |
| `MockAnalyticsService.swift` | Test implementation recording all events/errors for assertions |

## Troubleshooting

### Build Issues
```bash
make clean && make generate
```

### Package Resolution
```bash
make clean-packages && make setup
```

### Test Failures
```bash
make test-debug  # Verbose output
```

## API Keys

API keys are managed via **Firebase Remote Config** (primary) with fallbacks:

1. **Remote Config** - Primary source, fetched on app launch
2. **Environment variables** - Fallback for CI/CD
3. **Keychain** - Runtime storage for user-provided keys

```bash
# For CI/CD or local development without Remote Config
export GUARDIAN_API_KEY="your_key"
export NEWS_API_KEY="your_key"
export GNEWS_API_KEY="your_key"

# Supabase backend configuration (optional)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your_anon_key"
```

See `APIKeysProvider.swift` and `SupabaseConfig.swift` for implementation details. If Supabase is not configured, the app automatically falls back to the Guardian API.

## Deeplinks

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

### Push Notification Deeplinks

Push notifications can trigger deeplinks using three payload formats:

**Format 1: Full URL (Recommended)**
```json
{
  "aps": { "alert": "Breaking news!", "sound": "default" },
  "deeplink": "pulse://home"
}
```

**Format 2: Legacy Article Shorthand**
```json
{
  "aps": { "alert": "New article!", "sound": "default" },
  "articleID": "world/2024/jan/01/article-slug"
}
```

**Format 3: Type-Based**
```json
{
  "aps": { "alert": "Search results", "sound": "default" },
  "deeplinkType": "search",
  "deeplinkQuery": "swift"
}
```

| deeplinkType | Additional Fields |
|--------------|-------------------|
| `home`, `feed`, `bookmarks`, `settings` | None |
| `search` | `deeplinkQuery` (optional) |
| `article` | `deeplinkId` (required) |
