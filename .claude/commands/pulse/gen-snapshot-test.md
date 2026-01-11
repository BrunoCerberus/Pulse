# Generate Snapshot Test

Creates a Snapshot test class for visual regression testing of SwiftUI views and components.

## Usage

```
/pulse:gen-snapshot-test <ViewName>
```

## Arguments

- `ViewName`: PascalCase name of the view to test (e.g., `Profile`, `ArticleCard`)

## Output Location

```
# For feature views
PulseSnapshotTests/<FeatureName>/View/<ViewName>SnapshotTests.swift

# For design system components
PulseSnapshotTests/DesignSystem/Components/<ComponentName>SnapshotTests.swift
```

## Template: Feature View Snapshot Tests

```swift
@testable import Pulse
import EntropyCore
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class <ViewName>SnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Fixed date for snapshot stability (Jan 1, 2023 - consistent relative time)
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(<Service>.self, instance: Mock<Service>())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - Loading State

    func test<ViewName>Loading() {
        let view = NavigationStack {
            <ViewName>LoadingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Empty State

    func test<ViewName>Empty() {
        let view = NavigationStack {
            <ViewName>(
                router: <Feature>NavigationRouter(),
                viewModel: <Feature>ViewModel(serviceLocator: serviceLocator)
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Error State

    func test<ViewName>Error() {
        let view = NavigationStack {
            <ViewName>ErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Populated State

    func test<ViewName>Populated() {
        let view = NavigationStack {
            <ViewName>PopulatedPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}

// MARK: - Preview Helpers for State Testing

private struct <ViewName>LoadingPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading...")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("<Feature Name>")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct <ViewName>ErrorPreview: View {
    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)

                    Text("Unable to Load")
                        .font(Typography.titleMedium)

                    Text("Something went wrong. Please try again.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {} label: {
                        Text("Try Again")
                            .font(Typography.labelLarge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.Accent.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("<Feature Name>")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct <ViewName>PopulatedPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockItems: [<ItemType>] {
        // Create mock items with fixed dates for snapshot stability
        []
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                // Populated content here
            }
        }
        .navigationTitle("<Feature Name>")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
```

## Template: Component Snapshot Tests

```swift
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class <ComponentName>SnapshotTests: XCTestCase {

    // MARK: - Default Style

    func test<ComponentName>Default() {
        let view = <ComponentName>(/* default params */)
            .frame(width: 375)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Variant Styles

    func test<ComponentName>Variant() {
        let view = <ComponentName>(/* variant params */)
            .frame(width: 375)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Edge Cases

    func test<ComponentName>LongContent() {
        let view = <ComponentName>(/* long content */)
            .frame(width: 375)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func test<ComponentName>EmptyContent() {
        let view = <ComponentName>(/* empty/nil content */)
            .frame(width: 375)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
```

## Key Patterns

### 1. Use SnapshotConfig Helper

Always use the shared `SnapshotConfig` enum for consistent device configurations:

```swift
assertSnapshot(
    of: controller,
    as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
    record: false
)
```

Available configs:
- `SnapshotConfig.iPhoneAir` - Dark mode (default for CI)
- `SnapshotConfig.iPhoneAirLight` - Light mode
- `SnapshotConfig.iPad` - Tablet testing
- `SnapshotConfig.standardPrecision` - 0.99 (99%)

### 2. Fixed Dates for Stability

Always use fixed dates to prevent "2 hours ago" vs "3 hours ago" failures:

```swift
private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200) // Jan 1, 2023 00:00:00 UTC

private var snapshotArticle: Article {
    Article(
        id: "snapshot-1",
        title: "Test Article Title",
        publishedAt: fixedDate,  // Always use fixed date
        // ...
    )
}
```

### 3. Wait for Async Content

Use `.wait(for:on:)` to allow views to settle:

```swift
// Standard wait (1.0 second)
as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision))

// Longer wait for complex views (1.5 seconds)
as: .wait(for: 1.5, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision))
```

### 4. UIHostingController Wrapping

All SwiftUI views must be wrapped in UIHostingController:

```swift
let view = MyView()
let controller = UIHostingController(rootView: view)

assertSnapshot(of: controller, ...)
```

### 5. NavigationStack for Full Views

Wrap full-screen views in NavigationStack to capture navigation bar:

```swift
let view = NavigationStack {
    FeatureView(router: router, viewModel: viewModel)
}
let controller = UIHostingController(rootView: view)
```

### 6. Frame and Background for Components

Set explicit width and background for component tests:

```swift
let view = MyComponent()
    .frame(width: 375)  // iPhone width
    .padding()
    .background(LinearGradient.meshFallback)  // Visible background

let controller = UIHostingController(rootView: view)
```

### 7. Preview Helpers for States

Create private preview structs for testing different states:

```swift
private struct LoadingPreview: View { ... }
private struct ErrorPreview: View { ... }
private struct EmptyPreview: View { ... }
private struct PopulatedPreview: View { ... }
```

### 8. ServiceLocator Setup

For feature views, configure ServiceLocator with mocks:

```swift
override func setUp() {
    super.setUp()
    serviceLocator = ServiceLocator()
    serviceLocator.register(NewsService.self, instance: MockNewsService())
    serviceLocator.register(StorageService.self, instance: MockStorageService())
}
```

### 9. Window Setup for Complex Views

For views requiring full lifecycle (e.g., Settings with auth):

```swift
private var window: UIWindow!

override func setUp() {
    super.setUp()
    AuthenticationManager.shared.setAuthenticatedForTesting(.mock)
    window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    window.makeKeyAndVisible()
}

override func tearDown() {
    window?.isHidden = true
    window = nil
    AuthenticationManager.shared.setUnauthenticatedForTesting()
    super.tearDown()
}

func testView() {
    let controller = UIHostingController(rootView: view)
    window.rootViewController = controller
    controller.view.layoutIfNeeded()

    // Wait for settle
    let expectation = XCTestExpectation(description: "Wait for view to settle")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2.0)

    assertSnapshot(...)
}
```

### 10. Testing Multiple Variants (Categories, Styles)

Loop through variants with custom test names:

```swift
func testComponentAllCategories() {
    let categories: [NewsCategory] = [.business, .entertainment, .science]

    for category in categories {
        let view = MyComponent(category: category)
            .frame(width: 375)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false,
            testName: "testComponent_\(category.rawValue)"  // Custom name
        )
    }
}
```

## Common Imports

```swift
@testable import Pulse      // Access internal types
import EntropyCore          // ServiceLocator (for feature views)
import SnapshotTesting      // Snapshot testing framework
import SwiftUI              // SwiftUI views
import XCTest               // Test framework
```

## Test Naming Convention

| State | Test Name |
|-------|-----------|
| Loading | `test<ViewName>Loading` |
| Empty | `test<ViewName>Empty` |
| Error | `test<ViewName>Error` |
| Populated | `test<ViewName>Populated` |
| Variant | `test<ViewName><Variant>` |
| Style | `test<ComponentName><Style>Style` |

## Recording New Snapshots

To record new reference images, temporarily set `record: true`:

```swift
assertSnapshot(
    of: controller,
    as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
    record: true  // Set to true to record, then change back to false
)
```

**Important:** Always set `record: false` before committing!

## Instructions

1. **Ask if testing a feature view or component**
2. **For feature views:**
   - Ask about states to test (loading, empty, error, populated)
   - Ask about required services for ServiceLocator
   - Create preview helpers for each state
3. **For components:**
   - Ask about variants/styles to test
   - Ask about edge cases (long text, nil values, etc.)
4. Create the file following the appropriate template
5. Use `SnapshotConfig` helper for device configuration
6. Use fixed dates for any time-relative content
7. Wrap views properly (UIHostingController, NavigationStack if needed)
