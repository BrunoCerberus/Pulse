# Pulse

A modern iOS news aggregation app built with Clean Architecture, SwiftUI, and Combine. Powered by a self-hosted RSS feed aggregator backend with Guardian API fallback.

## Features

- **Authentication**: Firebase Auth with Google and Apple Sign-In (required before accessing app)
- **Home Feed**: Breaking news carousel, top headlines with infinite scrolling, and category tabs for filtering by followed topics (settings accessible via gear icon)
- **Media**: Browse and play Videos and Podcasts with in-app playback (YouTube videos open in YouTube app, podcasts use native AVPlayer)
- **Feed**: AI-powered Daily Digest summarizing latest news articles from the API using on-device LLM (Llama 3.2-1B) (**Premium**)
- **Article Summarization**: On-device AI article summarization via sparkles button (**Premium**)
- **Offline Experience**: Tiered cache (in-memory L1 + persistent disk L2), network monitoring via NWPathMonitor, offline banner, and graceful degradation preserving cached content
- **Bookmarks**: Save articles for offline reading with SwiftData persistence
- **Reading History**: Automatic tracking of read articles with SwiftData persistence, visual indicators on cards, and a dedicated history view accessible from Settings
- **Search**: Full-text search with 300ms debounce, suggestions, recent searches, and sort options
- **Localization**: Full multi-language support (English, Portuguese, Spanish) — both UI labels and content filtering follow the in-app language preference (via `AppLocalization` singleton), no app restart required
- **Settings**: Customize topics, notifications, theme, content language, content filters, and account/logout (accessed from Home navigation bar)
- **Accessibility**: Dynamic Type layout adaptation (HStack-to-VStack at accessibility sizes), VoiceOver heading hierarchy, focus management, and live announcements for async state changes
- **Security**: Input validation across WebView, deeplinks, URL handling, and Keychain-based app lock with biometric + passcode fallback
- **Onboarding**: 4-page first-launch experience shown once after sign-in, highlighting key features before entering the app
- **Analytics & Crash Reporting**: Firebase Analytics (18 type-safe events) and Crashlytics for crash/non-fatal error tracking
- **Widget**: Home screen widget showing recent headlines (WidgetKit extension)

The app uses iOS 26's liquid glass TabView style with tabs: Home, Media, Feed, Bookmarks, and Search. Users must sign in with Google or Apple before accessing the main app. A 4-page onboarding flow is shown once after first sign-in.

### Premium Features

The app uses StoreKit 2 for subscription management. Two AI-powered features require a premium subscription:

| Feature | Description |
|---------|-------------|
| AI Daily Digest | Summaries of the latest news across all categories |
| Article Summarization | On-device AI summaries for any article |

Non-premium users see a `PremiumGateView` on Feed or a paywall sheet when tapping the summarization button; both present the native StoreKit subscription UI.

## Architecture

Pulse implements a **Unidirectional Data Flow Architecture** based on Clean Architecture principles, using **Combine** for reactive data binding:

```
┌─────────────────────────────────────────────────────────────┐
│                         View Layer                          │
│              (SwiftUI + @ObservedObject ViewModel)          │
└─────────────────────────────────────────────────────────────┘
         │ ViewEvent                    ↑ @Published ViewState
         ↓                              │
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ViewModel (CombineViewModel) + EventActionMap + Reducer    │
└─────────────────────────────────────────────────────────────┘
         │ DomainAction                 ↑ DomainState (Combine)
         ↓                              │
┌─────────────────────────────────────────────────────────────┐
│                       Domain Layer                          │
│         Interactor (CombineInteractor + statePublisher)     │
└─────────────────────────────────────────────────────────────┘
         │                              ↑
         ↓                              │
┌─────────────────────────────────────────────────────────────┐
│                       Service Layer                         │
│           (Protocol-based + Live/Mock implementations)      │
└─────────────────────────────────────────────────────────────┘
         │                              ↑
         ↓                              │
┌─────────────────────────────────────────────────────────────┐
│                       Network Layer                         │
│                   (EntropyCore + SwiftData)                 │
└─────────────────────────────────────────────────────────────┘
```

### Key Protocols

| Protocol | Purpose |
|----------|---------|
| `CombineViewModel` | Base protocol for ViewModels with `viewState` and `handle(event:)` |
| `CombineInteractor` | Base protocol for domain layer with `statePublisher` and `dispatch(action:)` |
| `ViewStateReducing` | Transforms DomainState → ViewState |
| `DomainEventActionMap` | Maps ViewEvent → DomainAction |

### Navigation

The app uses a **Coordinator + Router** pattern with per-tab NavigationPaths:

```
CoordinatorView (@StateObject Coordinator)
       │
   TabView (selection: $coordinator.selectedTab)
       │
   ┌───┴───┬──────┬──────┬─────────┬───────┐
 Home   Media   Feed   Bookmarks  Search
   │        │           │         │
NavigationStack(path: $coordinator.homePath)
       │
.navigationDestination(for: Page.self)
       │
coordinator.build(page:)
```

- **Coordinator**: Central navigation manager owning all tab paths
- **CoordinatorView**: Root TabView with NavigationStacks per tab
- **Page**: Type-safe enum of all navigable destinations
- **NavigationRouter**: Feature-specific routers (conforming to EntropyCore protocol)
- **DeeplinkRouter**: Routes URL schemes through the Coordinator

Views are generic over their router type (`HomeView<R: HomeNavigationRouter>`) for testability.

## Quick Start: Adding a Feature

Follow these steps to add a new feature module to Pulse:

### 1. Create Feature Folder Structure

```
Pulse/
└── MyFeature/
    ├── API/
    │   ├── MyFeatureService.swift       # Protocol
    │   └── LiveMyFeatureService.swift   # Implementation
    ├── Domain/
    │   ├── MyFeatureDomainState.swift
    │   ├── MyFeatureDomainAction.swift
    │   ├── MyFeatureDomainInteractor.swift
    │   ├── MyFeatureEventActionMap.swift
    │   └── MyFeatureViewStateReducer.swift
    ├── ViewModel/
    │   └── MyFeatureViewModel.swift
    ├── View/
    │   └── MyFeatureView.swift
    ├── ViewEvents/
    │   └── MyFeatureViewEvent.swift
    ├── ViewStates/
    │   └── MyFeatureViewState.swift
    └── Router/
        └── MyFeatureNavigationRouter.swift
```

### 2. Define the Service Protocol

```swift
// API/MyFeatureService.swift
protocol MyFeatureService {
    func fetchData() -> AnyPublisher<[MyModel], Error>
}
```

### 3. Create Domain State and Actions

```swift
// Domain/MyFeatureDomainState.swift
struct MyFeatureDomainState: Equatable {
    var items: [MyModel] = []
    var isLoading: Bool = false
    var error: String?
}

// Domain/MyFeatureDomainAction.swift
enum MyFeatureDomainAction {
    case loadData
    case dataLoaded([MyModel])
    case loadFailed(String)
}
```

### 4. Implement the Interactor

```swift
// Domain/MyFeatureDomainInteractor.swift
@MainActor
final class MyFeatureDomainInteractor: CombineInteractor {
    typealias DomainState = MyFeatureDomainState
    typealias DomainAction = MyFeatureDomainAction

    private let stateSubject = CurrentValueSubject<DomainState, Never>(.init())
    var statePublisher: AnyPublisher<DomainState, Never> { stateSubject.eraseToAnyPublisher() }

    private let myService: MyFeatureService

    init(serviceLocator: ServiceLocator) {
        self.myService = try! serviceLocator.retrieve(MyFeatureService.self)
    }

    func dispatch(action: DomainAction) {
        switch action {
        case .loadData:
            loadData()
        case .dataLoaded(let items):
            stateSubject.value.items = items
            stateSubject.value.isLoading = false
        case .loadFailed(let error):
            stateSubject.value.error = error
            stateSubject.value.isLoading = false
        }
    }
}
```

### 5. Register the Service

In `PulseSceneDelegate.registerLiveServices()` (and add a mock in test setup if needed):

```swift
serviceLocator.register(MyFeatureService.self, instance: LiveMyFeatureService())
```

### 6. Add Navigation (if needed)

Add a case to `Page.swift` and implement `build(page:)` in `Coordinator`.

## Common Patterns

### Event to Action Mapping

```swift
// Domain/MyFeatureEventActionMap.swift
struct MyFeatureEventActionMap: DomainEventActionMap {
    func map(event: MyFeatureViewEvent) -> MyFeatureDomainAction? {
        switch event {
        case .onAppear:
            return .loadData
        case .onRefresh:
            return .loadData
        case .onItemTapped(let id):
            return .selectItem(id)
        }
    }
}
```

### View State Reduction

```swift
// Domain/MyFeatureViewStateReducer.swift
struct MyFeatureViewStateReducer: ViewStateReducing {
    func reduce(domainState: MyFeatureDomainState) -> MyFeatureViewState {
        MyFeatureViewState(
            items: domainState.items.map { ItemViewItem(from: $0) },
            isLoading: domainState.isLoading,
            showEmptyState: domainState.items.isEmpty && !domainState.isLoading,
            errorMessage: domainState.error
        )
    }
}
```

### Generic Router Pattern

```swift
// Router/MyFeatureNavigationRouter.swift
@MainActor
protocol MyFeatureNavigationRouter: NavigationRouter where NavigationEvent == MyFeatureNavigationEvent {}

enum MyFeatureNavigationEvent {
    case itemDetail(MyModel)
    case settings
}

@MainActor
final class MyFeatureNavigationRouterImpl: MyFeatureNavigationRouter {
    private weak var coordinator: Coordinator?

    init(coordinator: Coordinator? = nil) {
        self.coordinator = coordinator
    }

    func route(navigationEvent: MyFeatureNavigationEvent) {
        switch navigationEvent {
        case .itemDetail(let item):
            coordinator?.push(page: .itemDetail(item))
        case .settings:
            coordinator?.push(page: .settings)
        }
    }
}
```

### Testing with Mock Services

```swift
// In Tests
func createTestServiceLocator() -> ServiceLocator {
    let serviceLocator = ServiceLocator()
    serviceLocator.register(MyFeatureService.self, instance: MockMyFeatureService())
    return serviceLocator
}

@Test func testDataLoading() async {
    let serviceLocator = createTestServiceLocator()
    let interactor = MyFeatureDomainInteractor(serviceLocator: serviceLocator)

    interactor.dispatch(action: .loadData)

    // Assert state changes...
}
```

## Requirements

- Xcode 26.2+
- iOS 26.2+
- Swift 5.0+

## Setup

### 1. Install XcodeGen

```bash
brew install xcodegen
```

### 2. Generate Project

```bash
make setup
```

### 3. Open in Xcode

```bash
open Pulse.xcodeproj
```

### 4. API Keys

API keys are managed via **Firebase Remote Config** (primary) with environment variable fallback for CI/CD:

```bash
# For CI/CD or local development without Remote Config
export GUARDIAN_API_KEY="your_guardian_key"
export NEWS_API_KEY="your_newsapi_key"
export GNEWS_API_KEY="your_gnews_key"

# Supabase backend configuration (optional - falls back to Guardian API)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your_anon_key"
```

The app fetches keys from Remote Config on launch. Environment variables are used as fallback when Remote Config is unavailable. If Supabase is not configured, the app automatically falls back to the Guardian API. `APIKeysProvider` also supports `NEWS_API_KEY` and `GNEWS_API_KEY` (wired for future providers).

## Commands

| Command | Description |
|---------|-------------|
| `make init` | Setup Mint, SwiftFormat, and SwiftLint |
| `make install-xcodegen` | Install XcodeGen using Homebrew |
| `make generate` | Generate project from project.yml |
| `make setup` | install-xcodegen + generate |
| `make xcode` | Generate project and open in Xcode |
| `make build` | Build for development |
| `make build-release` | Build for release |
| `make bump-patch` | Increase patch version (0.0.x) |
| `make bump-minor` | Increase minor version (0.x.0) |
| `make bump-major` | Increase major version (x.0.0) |
| `make test` | Run all tests |
| `make test-unit` | Run unit tests only |
| `make test-ui` | Run UI tests only |
| `make test-snapshot` | Run snapshot tests only |
| `make test-debug` | Verbose unit test output |
| `make coverage` | Run tests with coverage report |
| `make coverage-report` | Per-file coverage report |
| `make coverage-badge` | Generate SVG coverage badge |
| `make lint` | Run SwiftFormat and SwiftLint |
| `make format` | Auto-format code |
| `make deeplink-test` | Run deeplink tests |
| `make clean` | Remove generated project |
| `make clean-packages` | Clean SPM caches |
| `make docs` | Generate DocC documentation |

## Project Structure

```
Pulse/
├── Pulse/
│   ├── Authentication/     # Firebase Auth (Google + Apple Sign-In)
│   │   ├── API/            # AuthService protocol + Live/Mock implementations
│   │   ├── Domain/         # AuthDomainInteractor, State, Action
│   │   ├── ViewModel/      # SignInViewModel
│   │   ├── View/           # SignInView
│   │   └── Manager/        # AuthenticationManager (global state)
│   ├── Home/               # Home feed with category filtering
│   ├── Media/              # Videos and Podcasts browsing
│   ├── MediaDetail/        # Video/Podcast playback (AVPlayer, WKWebView)
│   ├── Feed/               # AI-powered Daily Digest (Premium)
│   ├── Digest/             # On-device LLM infra (LLMService, LLMModelManager, prompts)
│   ├── Summarization/      # Article summarization (Premium)
│   ├── Search/             # Search functionality
│   ├── Bookmarks/          # Saved articles
│   ├── ReadingHistory/     # Reading history tracking (SwiftData)
│   ├── Settings/           # User preferences + account/logout
│   ├── ArticleDetail/      # Article view
│   ├── AppLock/            # Biometric/passcode app lock
│   ├── Onboarding/         # First-launch onboarding flow
│   ├── Paywall/            # StoreKit paywall UI
│   ├── SplashScreen/       # Launch animation
│   └── Configs/
│       ├── Navigation/     # Coordinator, Page, CoordinatorView, DeeplinkRouter, AnimatedTabView
│       ├── DesignSystem/   # ColorSystem, Typography, Components, DynamicTypeHelpers, HapticManager
│       ├── Models/         # Article, NewsCategory, UserPreferences, AppLocalization
│       ├── Networking/     # APIKeysProvider, BaseURLs, SupabaseConfig, RemoteConfig, NetworkMonitorService
│       ├── Storage/        # StorageService (SwiftData)
│       ├── Analytics/      # AnalyticsService protocol + LiveAnalyticsService
│       ├── Mocks/          # Mock services for testing
│       └── Widget/         # WidgetDataManager
├── PulseWidgetExtension/   # WidgetKit extension
├── PulseTests/             # Unit tests (Swift Testing)
├── PulseUITests/           # UI tests (XCTest)
├── PulseSnapshotTests/     # Snapshot tests (SnapshotTesting)
├── .github/workflows/      # CI/CD
└── .claude/commands/       # Claude Code integration
```

## Dependencies

| Package | Purpose |
|---------|---------|
| [EntropyCore](https://github.com/BrunoCerberus/EntropyCore) | UDF architecture protocols, networking, DI container |
| [Firebase](https://github.com/firebase/firebase-ios-sdk) | Authentication, Analytics, Crashlytics |
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) | Google Sign-In SDK |
| [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) | Snapshot testing |
| [Lottie](https://github.com/airbnb/lottie-ios) | Animations |
| LocalLlama (local package) | On-device LLM inference via [llama.cpp](https://github.com/ggml-org/llama.cpp) |

## CI/CD

GitHub Actions workflows:

- **ci.yml**: Runs on PRs - code quality, build, tests
- **claude.yml**: Claude Code on @claude mentions (issues/PRs/comments)
- **claude-code-review.yml**: Claude Code review on PR open/sync
- **scheduled-tests.yml**: Daily test runs at 2 AM UTC

## Schemes

| Scheme | Purpose |
|--------|---------|
| `PulseDev` | Development with all tests |
| `PulseProd` | Production release |
| `PulseTests` | Unit tests only |
| `PulseUITests` | UI tests only |
| `PulseSnapshotTests` | Snapshot tests only |

## Deeplinks

| Deeplink | Description |
|----------|-------------|
| `pulse://home` | Open home tab |
| `pulse://media` | Open Media tab (Videos & Podcasts) |
| `pulse://feed` | Open Feed tab (AI Daily Digest) |
| `pulse://bookmarks` | Open bookmarks tab |
| `pulse://search` | Open search tab |
| `pulse://search?q=query` | Search with query |
| `pulse://settings` | Open settings (pushes onto Home) |
| `pulse://article?id=path/to/article` | Open specific article by Guardian content ID |

## Testing

### Unit Tests
Tests for ViewModels, Interactors, and business logic using Swift Testing framework.

### UI Tests
End-to-end tests for navigation and user flows using XCTest, plus iOS 17+ accessibility audits (`performAccessibilityAudit()`) on all main screens.

### Snapshot Tests
Visual regression tests for UI components using SnapshotTesting, including Dynamic Type accessibility snapshot tests validating layout adaptation at large text sizes.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `make lint` and `make test`
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Data Sources

### Supabase Backend (Primary)

The app fetches articles from a self-hosted RSS feed aggregator backend that:

- Aggregates news from multiple RSS sources (Guardian, BBC, TechCrunch, Science Daily, etc.)
- Extracts high-resolution `og:image` from article pages for hero images
- Extracts full article content using go-readability (Mozilla Readability port)
- Stores articles in Supabase database with automatic cleanup

### Guardian API (Fallback)

When Supabase is not configured, the app falls back to the Guardian API directly.

## Acknowledgments

- [Supabase](https://supabase.com) - Backend database and REST API
- [Guardian API](https://open-platform.theguardian.com) - Fallback news data provider
