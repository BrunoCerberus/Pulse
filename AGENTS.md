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
│   ├── [Feature]/              # Feature modules (Home, Search, Bookmarks, etc.)
│   │   └── API/                # Service protocols + SupabaseAPI, SupabaseModels
│   ├── Feed/                   # AI-powered Daily Digest
│   │   ├── API/                # FeedService protocol + Live/Mock
│   │   ├── Domain/             # FeedDomainInteractor, State, Action, Reducer, EventActionMap
│   │   ├── ViewModel/          # FeedViewModel
│   │   ├── View/               # FeedView, DigestCard, StreamingTextView, BentoGrid components
│   │   │   └── BentoGrid/      # BentoDigestGrid, StatsCard, TopicsBreakdownCard, ContentSectionCard
│   │   ├── ViewEvents/         # FeedViewEvent
│   │   ├── ViewStates/         # FeedViewState
│   │   ├── Router/             # FeedNavigationRouter
│   │   └── Models/             # DailyDigest, FeedDigestPromptBuilder
│   │   ├── API/                # DigestService protocol + Live/Mock
│   │   ├── AI/                 # LLMService, LLMModelManager (llama.cpp via LocalLlama)
│   │   ├── Domain/             # DigestDomainInteractor, State, Action
│   │   ├── ViewModel/          # DigestViewModel
│   │   ├── View/               # DigestView, source selection components
│   │   ├── Router/             # DigestNavigationRouter
│   │   └── Models/             # DigestResult, DigestPromptBuilder
│   │   ├── API/                # Service protocols + implementations
│   │   ├── Domain/             # Interactor, State, Action, Reducer, EventActionMap
│   │   ├── ViewModel/          # CombineViewModel implementation
│   │   ├── View/               # SwiftUI views (generic over Router)
│   │   ├── ViewEvents/         # User interaction events
│   │   ├── ViewStates/         # Presentation-layer state
│   │   └── Router/             # Navigation routers (NavigationRouter protocol)
│   └── Configs/
│       ├── Navigation/         # Coordinator, Page, CoordinatorView, DeeplinkRouter
│       ├── Extensions/         # SwipeBackGesture and other utilities
│       ├── DesignSystem/       # ColorSystem, Typography, Components
│       ├── Models/             # Article, NewsCategory, UserPreferences
│       ├── Storage/            # StorageService (SwiftData)
│       ├── Mocks/              # Mock services for testing
│       └── ...                 # Other shared infrastructure
├── PulseTests/                 # Unit tests (Swift Testing)
├── PulseUITests/               # UI tests (XCTest)
├── PulseSnapshotTests/         # Snapshot tests (SnapshotTesting)
├── .github/workflows/          # CI/CD
└── .claude/commands/           # Claude slash commands
```

## Build & Test Commands

```bash
make setup          # Initial project setup
make test           # Run all tests
make test-unit      # Run unit tests only
make test-ui        # Run UI tests only
make test-snapshot  # Run snapshot tests only
make lint           # Code quality checks
make format         # Auto-format code
make coverage       # Test with coverage
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
8. **AuthenticationManager is a singleton** - observed by RootView to switch between SignInView and CoordinatorView
9. **Premium features are gated** - AI features require subscription (checked via StoreKitService)
10. **Service decorators for cross-cutting concerns** - Use Decorator Pattern for caching, logging (e.g., `CachingNewsService` wraps `LiveNewsService`)
11. **Graceful fallback for data sources** - Live services (NewsService, SearchService, ForYouService) use Supabase as primary and fall back to Guardian API when not configured or on error

## Data Source Architecture

The app uses a two-tier data source strategy:

| Source | Type | Description |
|--------|------|-------------|
| Supabase Backend | Primary | Self-hosted RSS aggregator with og:image and content extraction |
| Guardian API | Fallback | Direct API access when Supabase is not configured |

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

    var heroImageURL: String? {
        imageURL ?? thumbnailURL  // Prefer high-res for hero display
    }
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

## On-Device AI (Digest Feature)

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
- **CPU inference**: Small models (~1B params) run faster on CPU than GPU due to Metal transfer overhead
- **Flash attention**: Enabled for faster KV cache operations
- **Memory mapping**: Model loaded via mmap for faster startup
- **Model preloading**: Triggered when Feed tab appears (parallel with history fetch)

## Navigation Architecture

Pulse uses a **Coordinator + Router** pattern with per-tab NavigationPaths:

```
CoordinatorView (@StateObject Coordinator)
       │
   TabView (selection: $coordinator.selectedTab)
       │
   ┌───┴───┬──────┬─────────┬───────┐
 Home    Feed   Bookmarks  Search
   │        │           │         │
NavigationStack(path: $coordinator.homePath)
       │
.navigationDestination(for: Page.self)
       │
coordinator.build(page:)
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `RootView` | Auth-gated root (shows SignInView or CoordinatorView) |
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
6. Register service in SceneDelegate
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
3. Update/add snapshot tests
4. Test on multiple screen sizes

## API Keys

API keys are managed via **Firebase Remote Config** (primary) with fallbacks:

| Priority | Source | Purpose |
|----------|--------|---------|
| 1 | Remote Config | Primary source, fetched on app launch |
| 2 | Environment variables | CI/CD and local development |
| 3 | Keychain | Runtime storage for user-provided keys |

```bash
# Environment variable fallback for CI/CD
GUARDIAN_API_KEY      # Guardian API key (fallback data source)
SUPABASE_URL          # Supabase project URL (primary data source)
SUPABASE_ANON_KEY     # Supabase anonymous key
```

See `Configs/Networking/APIKeysProvider.swift` and `SupabaseConfig.swift` for implementation. If Supabase is not configured, the app automatically falls back to the Guardian API.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails | `make clean && make generate` |
| Tests timeout | Check async test waits |
| Snapshot mismatch | Run with `record: true` to update |
| Service not found | Verify ServiceLocator registration |
