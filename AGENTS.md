# Pulse - Agent Guidelines

## Repository Overview

Pulse is an iOS news aggregation app built with Clean Architecture. This document provides guidelines for AI agents and contributors working on the codebase.

## Project Structure

```
Pulse/
├── Pulse/                      # Main app source
│   ├── [Feature]/              # Feature modules
│   │   ├── API/                # Service layer
│   │   ├── Domain/             # Business logic
│   │   ├── ViewModel/          # Presentation
│   │   ├── View/               # SwiftUI
│   │   ├── ViewEvents/         # Event definitions
│   │   └── ViewStates/         # State definitions
│   └── Configs/                # Shared infrastructure
├── PulseTests/                 # Unit tests (Swift Testing)
├── PulseUITests/               # UI tests (XCTest)
├── PulseSnapshotTests/         # Snapshot tests
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

// 2. Type definition
final class HomeViewModel: CombineViewModel, ObservableObject {
    // 3. Type aliases
    typealias ViewState = HomeViewState

    // 4. Published properties
    @Published private(set) var viewState: HomeViewState = .initial

    // 5. Private properties
    private let interactor: HomeDomainInteractor
    private var cancellables = Set<AnyCancellable>()

    // 6. Initializer
    init(interactor: HomeDomainInteractor = HomeDomainInteractor()) {
        self.interactor = interactor
        setupBindings()
    }

    // 7. Public methods
    func handle(event: HomeViewEvent) { ... }

    // 8. Private methods
    private func setupBindings() { ... }
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
@Suite("FeatureViewModel Tests")
struct FeatureViewModelTests {
    var mockService: MockFeatureService!
    var sut: FeatureViewModel!

    init() {
        mockService = MockFeatureService()
        ServiceLocator.shared.register(FeatureService.self, service: mockService)
        sut = FeatureViewModel()
    }

    @Test("Initial state is correct")
    func testInitialState() {
        #expect(sut.viewState == .initial)
    }
}
```

### Mock Services
- All services have mock implementations in `Configs/Mocks/`
- Register mocks via ServiceLocator before testing
- Mocks expose result properties for test control

## Architecture Rules

1. **Views never directly access Services** - always through ViewModels
2. **ViewModels never directly access APIs** - always through Interactors
3. **Domain layer is UI-agnostic** - no SwiftUI imports
4. **All dependencies injected via ServiceLocator**

## Data Flow

```
User Interaction
      ↓
View.handle(event:)
      ↓
ViewModel.handle(event:)
      ↓
EventActionMap.map(event:) → DomainAction
      ↓
Interactor.dispatch(action:)
      ↓
Service method call
      ↓
DomainState update
      ↓
ViewStateReducer.reduce(domainState:) → ViewState
      ↓
View re-renders
```

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

## Environment Variables

```bash
NEWS_API_KEY      # NewsAPI.org key
GUARDIAN_API_KEY  # Guardian API key
GNEWS_API_KEY     # GNews API key
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails | `make clean && make generate` |
| Tests timeout | Check async test waits |
| Snapshot mismatch | Run with `record: true` to update |
| Service not found | Verify ServiceLocator registration |
