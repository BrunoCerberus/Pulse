# Pulse - Claude Code Instructions

## Project Overview

Pulse is an iOS news aggregation app built with **Unidirectional Data Flow Architecture** based on Clean Architecture principles, using **Combine** for reactive data binding. The app fetches news from the **Guardian API** (primary) and provides a personalized reading experience.

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
   // Service Registration (PulseSceneDelegate.swift)
   let serviceLocator = ServiceLocator()
   serviceLocator.register(NewsService.self, instance: LiveNewsService())
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
      ┌───┴───┬───────┬──────┬─────────┬───────┐
    Home   ForYou   Feed   Bookmarks  Search
      │       │          │           │         │
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
├── Authentication/             # Firebase Auth (Google + Apple Sign-In)
│   ├── API/                    # AuthService protocol + Live/Mock implementations
│   ├── Domain/                 # AuthDomainInteractor, State, Action
│   ├── ViewModel/              # SignInViewModel
│   ├── View/                   # SignInView
│   └── Manager/                # AuthenticationManager (global state)
├── Home/                       # Home feed feature
│   ├── API/                    # NewsAPI, NewsService
│   ├── Domain/                 # Interactor, State, Action, Reducer, EventActionMap
│   ├── ViewModel/              # HomeViewModel
│   ├── View/                   # SwiftUI views (generic over Router)
│   ├── ViewEvents/             # HomeViewEvent
│   ├── ViewStates/             # HomeViewState
│   └── Router/                 # HomeNavigationRouter
├── ForYou/                     # Personalized feed (same pattern)
├── Feed/                       # AI-powered Daily Digest
│   ├── API/                    # FeedService protocol + Live/Mock
│   ├── Domain/                 # FeedDomainInteractor, State, Action, Reducer, EventActionMap
│   ├── ViewModel/              # FeedViewModel
│   ├── View/                   # FeedView, DigestCard, StreamingTextView, SourceArticlesSection
│   ├── ViewEvents/             # FeedViewEvent
│   ├── ViewStates/             # FeedViewState
│   ├── Router/                 # FeedNavigationRouter
│   └── Models/                 # DailyDigest, FeedDigestPromptBuilder
├── Digest/                     # Article summarization (AI)
│   ├── API/                    # SummarizationService protocol + Live/Mock
│   ├── AI/                     # LLMService, LLMModelManager, LLMConfiguration
│   ├── Domain/                 # SummarizationDomainInteractor, State, Action
│   ├── ViewModel/              # SummarizationViewModel
│   └── View/                   # SummarizationSheet
├── Search/                     # Search feature
├── Bookmarks/                  # Offline reading
├── Settings/                   # User preferences (includes account/logout)
├── ArticleDetail/              # Article view
├── SplashScreen/               # App launch animation
└── Configs/
    ├── Navigation/             # Coordinator, Page, CoordinatorView, DeeplinkRouter
    ├── DesignSystem/           # ColorSystem, Typography, Components
    ├── Extensions/             # CombineViewModel, CombineInteractor, etc.
    ├── Models/                 # Article, NewsCategory, UserPreferences
    ├── Storage/                # StorageService (SwiftData)
    ├── Networking/             # API keys, base URLs
    ├── Mocks/                  # Mock services for testing
    └── Widget/                 # WidgetDataManager
```

## Features

| Feature | Description |
|---------|-------------|
| **Authentication** | Firebase Auth with Google and Apple Sign-In (required before accessing app) |
| **Home** | Breaking news carousel, top headlines with infinite scroll, settings access via gear icon |
| **For You** | Personalized feed based on followed topics |
| **Feed** | AI-powered Daily Digest summarizing articles read in last 48 hours using on-device LLM (Llama 3.2-1B) |
| **Search** | Full-text search with 300ms debounce, suggestions, and sort options (last tab with liquid glass style) |
| **Bookmarks** | Save articles for offline reading (SwiftData) |
| **Settings** | Topics, notifications, theme, muted content, account/logout (accessed from Home navigation bar) |

## Development Commands

```bash
# Setup
make setup              # Install XcodeGen + generate project
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

# Code Quality
make lint               # SwiftFormat + SwiftLint check
make format             # Auto-fix formatting

# Coverage
make coverage           # Run tests with coverage
make coverage-badge     # Generate SVG badge
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

```swift
enum GuardianAPI: APIFetcher {
    case search(query: String?, section: String?, page: Int, pageSize: Int, orderBy: String)
    case sections

    var path: String { ... }
    var method: HTTPMethod { .GET }
}

final class LiveNewsService: APIRequest, NewsService {
    func fetchTopHeadlines(country: String, page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: GuardianAPI.search(query: nil, section: nil, page: page, pageSize: 20, orderBy: "newest"),
            dataType: GuardianResponse.self
        )
        .map { $0.response.results.compactMap { $0.toArticle() } }
        .eraseToAnyPublisher()
    }
}
```

## Testing Strategy

### Unit Tests (Swift Testing)
- Test DomainInteractors with mock services
- Test ViewModels with mock interactors
- Test ViewStateReducers

### UI Tests (XCTest)
- Navigation flows
- Tab bar interactions
- Search functionality

### Snapshot Tests (SnapshotTesting)
- View components
- Loading states
- Empty states

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
| `RootView.swift` | Auth-gated root view (SignIn vs CoordinatorView) |
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
| `NewsAPI.swift` | API endpoint definitions |
| `GoogleService-Info.plist` | Firebase configuration |
| **AI/LLM** | |
| `LLMService.swift` | Protocol for LLM operations (load, generate, cancel) |
| `LiveLLMService.swift` | llama.cpp implementation via LocalLlama package |
| `LLMModelManager.swift` | Model lifecycle (load/unload, memory checks) |
| `LLMConfiguration.swift` | Model paths, inference parameters |

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
```

See `APIKeysProvider.swift` for the fallback hierarchy implementation.

## Deeplinks

```
pulse://home
pulse://search?q=query
pulse://bookmarks
pulse://feed
pulse://settings
pulse://article?id=123
```
