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

2. **ServiceLocator**: Centralized dependency injection
   ```swift
   ServiceLocator.shared.register(NewsService.self, service: LiveNewsService())
   let service = ServiceLocator.shared.resolve(NewsService.self)
   ```

3. **ViewStateReducing**: Transforms DomainState to ViewState
4. **DomainEventActionMap**: Maps ViewEvents to DomainActions

## Project Structure

```
Pulse/
├── Home/                    # Home feed feature
│   ├── API/                 # NewsAPI, NewsService
│   ├── Domain/              # Interactor, State, Action, Reducers
│   ├── ViewModel/           # HomeViewModel
│   ├── View/                # SwiftUI views
│   ├── ViewEvents/          # HomeViewEvent
│   └── ViewStates/          # HomeViewState
├── Search/                  # Search feature
├── Bookmarks/               # Offline reading
├── Categories/              # Category browsing
├── ForYou/                  # Personalized feed
├── Settings/                # User preferences
├── ArticleDetail/           # Article view
├── Configs/
│   ├── Storage/             # SwiftData persistence
│   ├── Networking/          # API keys, base URLs
│   ├── Extensions/          # Protocols
│   └── Mocks/               # Mock services for testing
└── SplashScreen/            # App launch
```

## Features

| Feature | Description |
|---------|-------------|
| **Home** | Breaking news carousel, top headlines with infinite scroll |
| **For You** | Personalized feed based on followed topics |
| **Categories** | Browse by World, Business, Tech, Science, Health, Sports, Entertainment |
| **Search** | Full-text search with suggestions and sort options |
| **Bookmarks** | Save articles for offline reading (SwiftData) |
| **Settings** | Topics, notifications, theme, muted content |

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
