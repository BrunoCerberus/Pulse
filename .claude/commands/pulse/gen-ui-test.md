# Generate UI Test

Creates a UI test class following the established single-flow-test pattern.

## Usage

```
/pulse:gen-ui-test <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
PulseUITests/<FeatureName>UITests.swift
```

## Template

```swift
import XCTest

final class <FeatureName>UITests: BaseUITestCase {

    // MARK: - Helper Methods (if needed)

    /// Helper description
    @discardableResult
    private func navigateTo<FeatureName>() -> Bool {
        // Navigate to the feature
        // Return true if successful
        return true
    }

    // MARK: - Combined Flow Test

    /// Tests <feature> navigation, content states, interactions, and related flows
    func test<FeatureName>Flow() throws {
        // --- Tab/Screen Navigation ---
        // Navigate to the feature and verify initial state

        // --- Content Loading ---
        // Verify content loads (success, empty, or error states)

        // --- User Interactions ---
        // Test primary interactions (taps, scrolls, etc.)

        // --- Navigation Flows ---
        // Test navigation to/from detail views

        // --- State Persistence ---
        // Verify state is maintained across tab switches

        // --- Error Handling ---
        // Verify error states have proper UI (Try Again button, etc.)
    }
}
```

## Key Patterns

### 1. Single Flow Test Method

Each UI test class has **exactly one** test method that covers the entire feature flow:

```swift
func test<FeatureName>Flow() throws {
    // All tests for this feature in one method
}
```

### 2. Inherit from BaseUITestCase

```swift
final class <FeatureName>UITests: BaseUITestCase {
```

This provides access to:
- `app` - XCUIApplication instance
- `Self.launchTimeout` (8s), `Self.defaultTimeout` (4s), `Self.shortTimeout` (1.5s)
- `navigateToTab(_:)`, `navigateToSearchTab()`, `navigateToFeedTab()`, etc.
- `navigateToSettings()`, `navigateBack()`
- `wait(for:)`, `waitForAny(_:timeout:)`, `waitForAnyMatch(_:timeout:)`
- `waitForHomeContent(timeout:)`, `waitForArticleDetail(timeout:)`
- `articleCards()`, `isElementVisible(_:)`, `scrollToElement(_:in:maxSwipes:)`

### 3. Section Comments

Use `// --- Section Name ---` to organize test sections:

```swift
func testFeatureFlow() throws {
    // --- Tab Navigation ---
    ...

    // --- Content Loading ---
    ...

    // --- User Interactions ---
    ...

    // --- Error Handling ---
    ...
}
```

### 4. Content State Handling

Always handle multiple content states:

```swift
// --- Content Loading ---
let successText = app.staticTexts["Success State"]
let emptyText = app.staticTexts["No Items"]
let errorText = app.staticTexts["Unable to Load"]

let contentLoaded = waitForAny([successText, emptyText, errorText], timeout: Self.defaultTimeout)

XCTAssertTrue(contentLoaded, "Feature should show content, empty, or error state")

if emptyText.exists {
    XCTAssertTrue(app.staticTexts["Help text"].exists, "Empty state should show helpful message")
}

if errorText.exists {
    XCTAssertTrue(app.buttons["Try Again"].exists, "Error state should have Try Again button")
}
```

### 5. Conditional Test Flows

Use conditional logic instead of early returns when possible:

```swift
let cards = articleCards()
if cards.count > 0 {
    cards.firstMatch.tap()

    let backButton = app.buttons["backButton"]
    XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should navigate to detail")

    backButton.tap()
    XCTAssertTrue(app.navigationBars["Feature"].waitForExistence(timeout: 5), "Should return")
}
```

### 6. Scroll Interactions

```swift
let scrollView = app.scrollViews.firstMatch

if scrollView.exists {
    // Pull to refresh
    scrollView.swipeDown()

    // Scroll down
    scrollView.swipeUp()
    scrollView.swipeUp()
}

XCTAssertTrue(navTitle.exists, "View should remain functional after scrolling")
```

### 7. Tab Switching Verification

```swift
// --- Tab Switching ---
let homeTab = app.tabBars.buttons["Home"]
homeTab.tap()

let homeNav = app.navigationBars["News"]
XCTAssertTrue(homeNav.waitForExistence(timeout: Self.defaultTimeout), "Home should load")

navigateTo<FeatureName>Tab()
XCTAssertTrue(app.navigationBars["<FeatureName>"].waitForExistence(timeout: Self.defaultTimeout),
    "<FeatureName> should be visible after tab switch")
```

### 8. Private Helper Methods

For complex navigation that's reused:

```swift
@discardableResult
private func navigateToArticleDetail() -> Bool {
    navigateToTab("Home")

    guard app.staticTexts["Top Headlines"].waitForExistence(timeout: 10) else {
        return false
    }

    let cards = articleCards()
    guard cards.count > 0 else { return false }

    cards.firstMatch.tap()
    return waitForArticleDetail()
}
```

## Common Element Queries

```swift
// Navigation bars
app.navigationBars["Title"]
app.navigationBars.buttons["gearshape"]
app.navigationBars.buttons["backButton"]

// Tab bar
app.tabBars.buttons["Home"]
app.tabBars.firstMatch

// Buttons
app.buttons["Button Title"]
app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'text'")).firstMatch

// Static text
app.staticTexts["Exact Text"]
app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'partial'")).firstMatch

// Text fields
app.searchFields.firstMatch
app.textFields["placeholder"]

// Scroll views
app.scrollViews.firstMatch
app.scrollViews["accessibilityIdentifier"]

// Article cards (via BaseUITestCase)
articleCards() // Returns buttons matching "articleCard" identifier
```

## Common Assertions

```swift
// Existence
XCTAssertTrue(element.exists, "Element should exist")
XCTAssertTrue(element.waitForExistence(timeout: 5), "Element should appear")

// Selection state
XCTAssertTrue(tab.isSelected, "Tab should be selected")

// Hittability
XCTAssertTrue(element.isHittable, "Element should be tappable")

// Multiple conditions
let appeared = waitForAny([element1, element2, element3], timeout: 10)
XCTAssertTrue(appeared, "One of the elements should appear")
```

## Example: Tab-Based Feature

```swift
import XCTest

final class ProfileUITests: BaseUITestCase {

    // MARK: - Combined Flow Test

    /// Tests Profile navigation, content states, editing, and settings integration
    func testProfileFlow() throws {
        // --- Tab Navigation ---
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.exists, "Profile tab should exist")

        profileTab.tap()
        XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected")

        let navTitle = app.navigationBars["Profile"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Profile nav should exist")

        // --- Content Loading ---
        let signedInText = app.staticTexts["Welcome back"]
        let signInButton = app.buttons["Sign In"]
        let errorText = app.staticTexts["Unable to Load Profile"]

        let contentLoaded = waitForAny([signedInText, signInButton, errorText], timeout: Self.defaultTimeout)
        XCTAssertTrue(contentLoaded, "Profile should show signed in, sign in prompt, or error state")

        if errorText.exists {
            XCTAssertTrue(app.buttons["Try Again"].exists, "Error state should have Try Again button")
        }

        // --- User Interactions ---
        if signedInText.exists {
            let editButton = app.buttons["Edit Profile"]
            if editButton.exists {
                editButton.tap()

                let saveButton = app.buttons["Save"]
                XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Edit mode should show Save button")

                app.buttons["Cancel"].tap()
            }
        }

        // --- Scroll and Navigation ---
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }

        XCTAssertTrue(navTitle.exists, "Profile should remain functional after scrolling")

        // --- Tab Switching ---
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.defaultTimeout), "Home should load")

        profileTab.tap()
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Profile should restore after tab switch")
    }
}
```

## Instructions

1. **Ask for the feature name** if not provided
2. **Ask what tab/navigation** accesses this feature
3. **Ask about content states** (success, empty, error, onboarding)
4. **Ask about primary interactions** to test (taps, scrolls, forms)
5. **Ask about navigation flows** (detail views, modals, settings)
6. Create the file following the single-flow-test pattern
7. Use section comments to organize the test flow
8. Handle all content states with conditional logic
