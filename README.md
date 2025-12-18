# Pulse

A modern iOS news aggregation app built with Clean Architecture, SwiftUI, and Combine.

## Features

- **Home Feed**: Breaking news carousel and top headlines with infinite scrolling (settings accessible via gear icon)
- **For You**: Personalized feed based on followed topics and reading history
- **Categories**: Browse news by World, Business, Technology, Science, Health, Sports, Entertainment
- **Search**: Full-text search with 300ms debounce, suggestions, recent searches, and sort options
- **Bookmarks**: Save articles for offline reading with SwiftData persistence
- **Settings**: Customize topics, notifications, theme, and content filters (accessed from Home navigation bar)

The app uses iOS 26's liquid glass TabView style with tabs: Home, For You, Categories, Bookmarks, and Search.

## Architecture

Pulse follows **Clean Architecture** with **MVVM** presentation layer:

```
┌─────────────────────────────────────────────────────────────┐
│                         View Layer                          │
│                    (SwiftUI + ViewState)                    │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│            (ViewModel + ViewStateReducer)                   │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                       Domain Layer                          │
│              (Interactor + DomainState)                     │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                       Service Layer                         │
│           (Protocol-based + Live/Mock impl)                 │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                       Network Layer                         │
│                      (EntropyCore)                          │
└─────────────────────────────────────────────────────────────┘
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

### 4. Configure API Keys

Set environment variables or add to scheme:

```bash
export NEWS_API_KEY="your_newsapi_key"
export GUARDIAN_API_KEY="your_guardian_key"
export GNEWS_API_KEY="your_gnews_key"
```

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
│   ├── Home/           # Home feed feature
│   ├── ForYou/         # Personalized feed
│   ├── Categories/     # Category browsing
│   ├── Search/         # Search functionality
│   ├── Bookmarks/      # Saved articles
│   ├── Settings/       # User preferences
│   ├── ArticleDetail/  # Article view
│   ├── Configs/        # Infrastructure
│   └── SplashScreen/   # Launch screen
├── PulseTests/         # Unit tests
├── PulseUITests/       # UI tests
├── PulseSnapshotTests/ # Snapshot tests
├── .github/workflows/  # CI/CD
└── .claude/commands/   # Claude Code integration
```

## Dependencies

| Package | Purpose |
|---------|---------|
| [EntropyCore](https://github.com/BrunoCerberus/EntropyCore) | Network layer abstraction |
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
pulse://category?name=tech      # Open category
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

- [NewsAPI](https://newsapi.org) - News data provider
- [Guardian API](https://open-platform.theguardian.com) - News data provider
- [GNews](https://gnews.io) - News data provider
