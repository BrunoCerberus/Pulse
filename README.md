# Pulse

A modern iOS news aggregation app built with Clean Architecture, SwiftUI, and Combine. Powered by the Guardian API.

## Features

- **Authentication**: Firebase Auth with Google and Apple Sign-In (required before accessing app)
- **Home Feed**: Breaking news carousel and top headlines with infinite scrolling (settings accessible via gear icon)
- **For You**: Personalized feed based on followed topics and reading history
- **Digest**: AI-powered personalized digest from bookmarks, reading history, or fresh news by followed topics
- **Search**: Full-text search with 300ms debounce, suggestions, recent searches, and sort options
- **Bookmarks**: Save articles for offline reading with SwiftData persistence
- **Settings**: Customize topics, notifications, theme, content filters, and account/logout (accessed from Home navigation bar)

The app uses iOS 26's liquid glass TabView style with tabs: Home, For You, Digest, Bookmarks, and Search. Users must sign in with Google or Apple before accessing the main app.

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
   ┌───┴───┬───────┬─────────┬─────────┐
 Home   ForYou   Digest  Bookmarks Search
   │       │        │          │        │
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
```

The app fetches keys from Remote Config on launch. Environment variables are used as fallback when Remote Config is unavailable.

## Commands

| Command | Description |
|---------|-------------|
| `make setup` | Install XcodeGen and generate project |
| `make build` | Build for development |
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
│   │   ├── API/            # NewsService protocol + LiveNewsService
│   │   ├── Domain/         # Interactor, State, Action, Reducer, EventActionMap
│   │   ├── ViewModel/      # HomeViewModel
│   │   ├── View/           # SwiftUI views
│   │   ├── ViewEvents/     # HomeViewEvent
│   │   ├── ViewStates/     # HomeViewState
│   │   └── Router/         # HomeNavigationRouter
│   ├── ForYou/             # Personalized feed (same pattern)
│   ├── Digest/             # AI-powered personalized digest
│   ├── Search/             # Search functionality
│   ├── Bookmarks/          # Saved articles
│   ├── Settings/           # User preferences + account/logout
│   ├── ArticleDetail/      # Article view
│   ├── SplashScreen/       # Launch animation
│   └── Configs/
│       ├── Navigation/     # Coordinator, Page, CoordinatorView, DeeplinkRouter
│       ├── DesignSystem/   # ColorSystem, Typography, Components, HapticManager
│       ├── Extensions/     # CombineViewModel, CombineInteractor, ViewStateReducing
│       ├── Models/         # Article, NewsCategory, UserPreferences
│       ├── Networking/     # APIKeysProvider, BaseURLs
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
| [EntropyCore](https://github.com/BrunoCerberus/EntropyCore) | Network layer abstraction |
| [Firebase](https://github.com/firebase/firebase-ios-sdk) | Authentication (Google + Apple Sign-In) |
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) | Google Sign-In SDK |
| [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) | Snapshot testing |
| [Lottie](https://github.com/airbnb/lottie-ios) | Animations |

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

```
pulse://home                    # Open home tab
pulse://search?q=query          # Search with query
pulse://bookmarks               # Open bookmarks
pulse://settings                # Open settings
pulse://article?id=123          # Open specific article
pulse://digest                  # Open digest
```

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

## Acknowledgments

- [Guardian API](https://open-platform.theguardian.com) - Primary news data provider
