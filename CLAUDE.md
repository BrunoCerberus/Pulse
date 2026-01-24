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
      ┌───┴───┬──────┬─────────┬───────┐
    Home    Feed   Bookmarks  Search
      │        │           │         │
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
├── Home/                       # Home feed with category filtering
│   ├── API/                    # NewsAPI, NewsService, SupabaseAPI, SupabaseModels
│   ├── Domain/                 # Interactor, State, Action, Reducer, EventActionMap
│   ├── ViewModel/              # HomeViewModel
│   ├── View/                   # SwiftUI views (includes category tabs)
│   ├── ViewEvents/             # HomeViewEvent
│   ├── ViewStates/             # HomeViewState
│   └── Router/                 # HomeNavigationRouter
├── Feed/                       # AI-powered Daily Digest
│   ├── API/                    # FeedService protocol + Live/Mock
│   ├── Domain/                 # FeedDomainInteractor, State, Action, Reducer, EventActionMap
│   ├── ViewModel/              # FeedViewModel
│   ├── View/                   # FeedView, DigestCard, StreamingTextView, BentoGrid components
│   │   └── BentoGrid/          # BentoDigestGrid, StatsCard, TopicsBreakdownCard, ContentSectionCard
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
    ├── Networking/             # API keys, base URLs, SupabaseConfig
    ├── Mocks/                  # Mock services for testing
    └── Widget/                 # WidgetDataManager
```

## Features

| Feature | Description |
|---------|-------------|
| **Authentication** | Firebase Auth with Google and Apple Sign-In (required before accessing app) |
| **Home** | Breaking news carousel, top headlines with infinite scroll, category tabs for filtering by followed topics, settings access via gear icon |
| **Feed** | AI-powered Daily Digest summarizing articles read in last 48 hours using on-device LLM (Llama 3.2-1B) (**Premium**) |
| **Article Summarization** | On-device AI article summarization via sparkles button (**Premium**) |
| **Search** | Full-text search with 300ms debounce, suggestions, and sort options (last tab with liquid glass style) |
| **Bookmarks** | Save articles for offline reading (SwiftData) |
| **Settings** | Topics, notifications, theme, muted content, account/logout (accessed from Home navigation bar) |

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

All Live services (LiveNewsService, LiveSearchService, LiveForYouService) use Supabase as the primary backend with Guardian API fallback.

### Supabase Backend (Primary)

```swift
enum SupabaseAPI: APIFetcher {
    case articles(page: Int, pageSize: Int)
    case articlesByCategory(category: String, page: Int, pageSize: Int)
    case breakingNews(since: String)
    case article(id: String)
    case search(query: String, page: Int, pageSize: Int, orderBy: String)

    var path: String { ... }
    var method: HTTPMethod { .GET }
}

final class LiveNewsService: APIRequest, NewsService {
    private let useSupabase: Bool

    override init() {
        self.useSupabase = SupabaseConfig.isConfigured
        super.init()
    }

    func fetchTopHeadlines(country: String, page: Int) -> AnyPublisher<[Article], Error> {
        if useSupabase {
            return fetchFromSupabase(page: page)
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

## Caching Layer

The app uses an in-memory caching layer to minimize Guardian API calls (500/day free tier limit):

```swift
// CachingNewsService wraps LiveNewsService using the Decorator Pattern
let cachingService = CachingNewsService(wrapping: LiveNewsService())
serviceLocator.register(NewsService.self, instance: cachingService)
```

### TTL Configuration

| Content Type | TTL | Rationale |
|-------------|-----|-----------|
| Breaking News | 5 min | High freshness expectation |
| Headlines Page 1 | 10 min | Balance freshness vs API savings |
| Headlines Page 2+ | 30 min | Less critical, saves API calls |
| Category Headlines | 10 min | Similar to page 1 |
| Individual Articles | 60 min | Content rarely changes |

### Cache Invalidation

Cache is automatically invalidated on pull-to-refresh:

```swift
// HomeDomainInteractor.refresh()
if let cachingService = newsService as? CachingNewsService {
    cachingService.invalidateCache()
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
| `NewsAPI.swift` | Guardian API endpoint definitions |
| `GoogleService-Info.plist` | Firebase configuration |
| **Supabase Backend** | |
| `SupabaseConfig.swift` | Supabase URL and API key configuration |
| `SupabaseAPI.swift` | Supabase REST API endpoint definitions |
| `SupabaseModels.swift` | Supabase response models (SupabaseArticle, SupabaseSource, SupabaseCategory) |
| **Caching** | |
| `NewsCacheStore.swift` | Cache protocol, NSCache implementation, TTL configuration |
| `CachingNewsService.swift` | Decorator wrapping LiveNewsService with in-memory caching |
| **AI/LLM** | |
| `LLMService.swift` | Protocol for LLM operations (load, generate, cancel) |
| `LiveLLMService.swift` | llama.cpp implementation via LocalLlama package |
| `LLMModelManager.swift` | Model lifecycle (load/unload, memory checks) |
| `LLMConfiguration.swift` | Model paths, inference parameters (context size, batch size) |
| **LLM Performance** | CPU inference (faster than GPU for small models), flash attention, mmap loading, model preloading |
| **Premium/Subscription** | |
| `StoreKitService.swift` | Protocol for subscription status and purchases |
| `LiveStoreKitService.swift` | StoreKit 2 implementation |
| `MockStoreKitService.swift` | Mock for testing (respects `MOCK_PREMIUM` env var) |
| `PremiumGateView.swift` | Reusable premium upsell component |
| `PremiumFeature.swift` | Enum defining gated features |
| `PaywallView.swift` | Native StoreKit subscription UI |

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

# Supabase backend configuration (optional)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your_anon_key"
```

See `APIKeysProvider.swift` and `SupabaseConfig.swift` for implementation details. If Supabase is not configured, the app automatically falls back to the Guardian API.

## Deeplinks

| Deeplink | Description | Status |
|----------|-------------|--------|
| `pulse://home` | Open home tab | ✅ Full |
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
