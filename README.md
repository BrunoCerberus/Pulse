# Pulse

A modern iOS news aggregation app built with Clean Architecture, SwiftUI, and Combine. Powered by a self-hosted RSS feed aggregator backend with Guardian API fallback.

## Features

- **Authentication**: Firebase Auth with Google and Apple Sign-In (required before accessing app)
- **Home Feed**: Breaking news carousel and top headlines with infinite scrolling (settings accessible via gear icon)
- **For You**: Personalized feed based on followed topics and reading history (**Premium**)
- **Feed**: AI-powered Daily Digest summarizing articles read in the last 48 hours using on-device LLM (Llama 3.2-1B) (**Premium**)
- **Article Summarization**: On-device AI article summarization via sparkles button (**Premium**)
- **Bookmarks**: Save articles for offline reading with SwiftData persistence
- **Search**: Full-text search with 300ms debounce, suggestions, recent searches, and sort options
- **Settings**: Customize topics, notifications, theme, content filters, and account/logout (accessed from Home navigation bar)

The app uses iOS 26's liquid glass TabView style with tabs: Home, For You, Feed, Bookmarks, and Search. Users must sign in with Google or Apple before accessing the main app.

### Premium Features

The app uses StoreKit 2 for subscription management. Three AI-powered features require a premium subscription:

| Feature | Description |
|---------|-------------|
| AI Daily Digest | Personalized summaries of your reading activity |
| Personalized For You | Curated feed based on interests and reading habits |
| Article Summarization | On-device AI summaries for any article |

Non-premium users see a `PremiumGateView` with an "Unlock Premium" button that presents the native StoreKit subscription UI.

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
   ┌───┴───┬───────┬──────┬─────────┬───────┐
 Home   ForYou   Feed   Bookmarks  Search
   │       │          │           │         │
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

In `PulseSceneDelegate.setupServices()`:

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

- Xcode 26.0.1+
- iOS 26.1+
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

# Supabase backend configuration (optional - falls back to Guardian API)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your_anon_key"
```

The app fetches keys from Remote Config on launch. Environment variables are used as fallback when Remote Config is unavailable. If Supabase is not configured, the app automatically falls back to the Guardian API.

## Commands

| Command | Description |
|---------|-------------|
| `make setup` | Install XcodeGen and generate project |
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
| `make coverage` | Run tests with coverage report |
| `make lint` | Run SwiftFormat and SwiftLint |
| `make format` | Auto-format code |
| `make clean` | Remove generated project |

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
│   ├── Home/               # Home feed feature
│   │   ├── API/            # NewsService, SupabaseAPI, SupabaseModels
│   │   ├── Domain/         # Interactor, State, Action, Reducer, EventActionMap
│   │   ├── ViewModel/      # HomeViewModel
│   │   ├── View/           # SwiftUI views
│   │   ├── ViewEvents/     # HomeViewEvent
│   │   ├── ViewStates/     # HomeViewState
│   │   └── Router/         # HomeNavigationRouter
│   ├── ForYou/             # Personalized feed (same pattern)
│   ├── Feed/               # AI-powered Daily Digest
│   ├── Search/             # Search functionality
│   ├── Bookmarks/          # Saved articles
│   ├── Settings/           # User preferences + account/logout
│   ├── ArticleDetail/      # Article view
│   ├── SplashScreen/       # Launch animation
│   └── Configs/
│       ├── Navigation/     # Coordinator, Page, CoordinatorView, DeeplinkRouter
│       ├── DesignSystem/   # ColorSystem, Typography, Components, HapticManager
│       ├── Extensions/     # SwipeBackGesture and other utilities
│       ├── Models/         # Article, NewsCategory, UserPreferences
│       ├── Networking/     # APIKeysProvider, BaseURLs, SupabaseConfig
│       ├── Storage/        # StorageService (SwiftData)
│       ├── Mocks/          # Mock services for testing
│       └── Widget/         # WidgetDataManager
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
| [Firebase](https://github.com/firebase/firebase-ios-sdk) | Authentication (Google + Apple Sign-In) |
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) | Google Sign-In SDK |
| [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) | Snapshot testing |
| [Lottie](https://github.com/airbnb/lottie-ios) | Animations |
| LocalLlama (local package) | On-device LLM inference via [llama.cpp](https://github.com/ggml-org/llama.cpp) |

## CI/CD

GitHub Actions workflows:

- **ci.yml**: Runs on PRs - code quality, build, tests
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
| `pulse://forYou` | Open For You tab (Premium) |
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
End-to-end tests for navigation and user flows using XCTest.

### Snapshot Tests
Visual regression tests for UI components using SnapshotTesting.

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
- Extracts full article content using Mozilla Readability
- Stores articles in Supabase database with automatic cleanup

### Guardian API (Fallback)

When Supabase is not configured, the app falls back to the Guardian API directly.

## Acknowledgments

- [Supabase](https://supabase.com) - Backend database and REST API
- [Guardian API](https://open-platform.theguardian.com) - Fallback news data provider
