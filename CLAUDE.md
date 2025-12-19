# Pulse - Claude Code Instructions

## Project Overview

Pulse is an iOS news aggregation app built with **Clean Architecture**, **MVVM**, and **Combine**. The app fetches news from public APIs (NewsAPI, Guardian API, GNews) and provides a personalized reading experience.

## Architecture

```
View (SwiftUI)
    ↓ ViewEvent
ViewModel (@Published viewState)
    ↓ DomainAction
DomainInteractor (Combine publishers)
    ↓
Service Layer (Protocol-based)
    ↓
Network Layer (EntropyCore)
```

### Key Patterns

1. **Clean Architecture**: Strict separation of concerns
   - **View Layer**: SwiftUI views with `@StateObject`
   - **Presentation Layer**: ViewModels implementing `CombineViewModel`
   - **Domain Layer**: Interactors implementing `CombineInteractor`
   - **Service Layer**: Protocol-based services with Live/Mock implementations

2. **ServiceLocator**: Instance-based dependency injection (passed through initializers)
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

3. **ViewStateReducing**: Transforms DomainState to ViewState
4. **DomainEventActionMap**: Maps ViewEvents to DomainActions

5. **Coordinator + Router Navigation**: Centralized navigation with per-tab paths
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
├── Home/                    # Home feed feature
│   ├── API/                 # NewsAPI, NewsService
│   ├── Domain/              # Interactor, State, Action, Reducers
│   ├── ViewModel/           # HomeViewModel
│   ├── View/                # SwiftUI views (generic over Router)
│   ├── ViewEvents/          # HomeViewEvent
│   ├── ViewStates/          # HomeViewState
│   └── Router/              # HomeNavigationRouter
├── Search/                  # Search feature
├── Bookmarks/               # Offline reading
├── Categories/              # Category browsing
├── ForYou/                  # Personalized feed
├── Settings/                # User preferences
├── ArticleDetail/           # Article view
├── Configs/
│   ├── Navigation/          # Coordinator, Page, CoordinatorView, DeeplinkRouter
│   ├── Storage/             # SwiftData persistence
│   ├── Networking/          # API keys, base URLs
│   ├── Extensions/          # Protocols
│   └── Mocks/               # Mock services for testing
└── SplashScreen/            # App launch
```

## Features

| Feature | Description |
|---------|-------------|
| **Home** | Breaking news carousel, top headlines with infinite scroll, settings access via gear icon |
| **For You** | Personalized feed based on followed topics |
| **Categories** | Browse by World, Business, Tech, Science, Health, Sports, Entertainment |
| **Search** | Full-text search with 300ms debounce, suggestions, and sort options (last tab with liquid glass style) |
| **Bookmarks** | Save articles for offline reading (SwiftData) |
| **Settings** | Topics, notifications, theme, muted content (accessed from Home navigation bar) |

## Development Commands

```bash
# Setup
make setup              # Install XcodeGen + generate project

# Building
make build              # Debug build
make build-release      # Release build

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
| `/coverage` | Generate coverage report |
| `/run` | Build and open in Xcode |
| `/push` | Stage, commit, and push |
| `/reset` | Discard all changes |

## Network Layer (EntropyCore)

```swift
enum NewsAPI: APIFetcher {
    case topHeadlines(country: String, page: Int)
    case everything(query: String, page: Int, sortBy: String)

    var path: String { ... }
    var method: HTTPMethod { .GET }
    var queryItems: [URLQueryItem]? { ... }
}

final class LiveNewsService: APIRequest, NewsService {
    func fetchTopHeadlines(country: String, page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(target: NewsAPI.topHeadlines(country: country, page: page), dataType: NewsResponse.self)
            .map { $0.articles.compactMap { $0.toArticle() } }
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
| `Coordinator.swift` | Central navigation manager with per-tab paths |
| `CoordinatorView.swift` | Root TabView with NavigationStacks |
| `Page.swift` | Enum of all navigable destinations |
| `DeeplinkRouter.swift` | Routes deeplinks to coordinator |
| `*NavigationRouter.swift` | Feature-specific navigation routers |
| `ServiceLocator.swift` | Dependency injection container |
| `DeeplinkManager.swift` | URL scheme handling |
| `ThemeManager.swift` | Dark/light mode management |
| `StorageService.swift` | SwiftData persistence |
| `NewsAPI.swift` | API endpoint definitions |

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

Set environment variables:
```bash
export NEWS_API_KEY="your_key"
export GUARDIAN_API_KEY="your_key"
export GNEWS_API_KEY="your_key"
```

## Deeplinks

```
pulse://home
pulse://search?q=query
pulse://bookmarks
pulse://settings
pulse://article?id=123
pulse://category?name=technology
```
