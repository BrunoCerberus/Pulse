# Comprehensive Test Implementation Guide - Phase 2-3

## 🎯 Status: 5 of 11 Tiers Complete (45% Done)

### ✅ COMPLETED TIERS

1. **TIER 1a** - LLM Services (503 + 354 lines)
   - `PulseTests/Digest/AI/LiveLLMServiceTests.swift`
   - `PulseTests/Digest/AI/LLMModelManagerTests.swift`

2. **TIER 1b** - Auth Services (491 lines)
   - `PulseTests/Authentication/API/LiveAuthServiceTests.swift`

3. **TIER 1c** - StoreKit Services (400+ lines)
   - `PulseTests/Paywall/API/StoreKitServiceTests.swift`

4. **TIER 1d** - Remote Config (300+ lines)
   - `PulseTests/Configs/Networking/RemoteConfigServiceTests.swift`

5. **TIER 1e** - News API Layer (500+ lines)
   - `PulseTests/Home/API/NewsAPITests.swift`

---

## 🚀 NEXT: TIER 1f - Storage Service

**Priority**: HIGH | **Effort**: MEDIUM | **Est. Lines**: 400+

### Target Files
- `Pulse/Configs/Storage/LiveStorageService.swift` (SwiftData wrapper)
- `Pulse/Configs/Storage/StorageService.swift` (protocol)

### Test Template

```swift
// File: PulseTests/Configs/Storage/StorageServiceTests.swift

import Foundation
@testable import Pulse
import Testing

@Suite("StorageService Protocol Tests")
struct StorageServiceProtocolTests {
    @Test("All protocol methods exist") { /* verification */ }
    @Test("Protocol returns correct types") { /* verification */ }
}

@Suite("MockStorageService Tests")
struct MockStorageServiceTests {
    let sut = MockStorageService()

    // Bookmarks
    @Test("Save article to bookmarks") { /* test */ }
    @Test("Delete bookmarked article") { /* test */ }
    @Test("Fetch all bookmarks") { /* test */ }
    @Test("Check if article is bookmarked") { /* test */ }

    // Reading History
    @Test("Save reading history") { /* test */ }
    @Test("Fetch all reading history") { /* test */ }
    @Test("Fetch recent reading history since date") { /* test */ }
    @Test("Clear reading history") { /* test */ }

    // Preferences
    @Test("Save user preferences") { /* test */ }
    @Test("Fetch user preferences") { /* test */ }
    @Test("Update preferences") { /* test */ }
}

@Suite("BookmarkedArticle Model Tests")
struct BookmarkedArticleTests {
    @Test("Initialize from article") { /* test */ }
    @Test("Convert back to article") { /* test */ }
    @Test("Saved timestamp is set") { /* test */ }
}

@Suite("ReadingHistoryEntry Model Tests")
struct ReadingHistoryEntryTests {
    @Test("Initialize from article") { /* test */ }
    @Test("Convert back to article") { /* test */ }
    @Test("Read timestamp is updated") { /* test */ }
}

@Suite("UserPreferencesModel Tests")
struct UserPreferencesModelTests {
    @Test("Initialize with defaults") { /* test */ }
    @Test("Update preferences") { /* test */ }
    @Test("Convert to UserPreferences") { /* test */ }
}
```

### Key Test Cases
- ✅ Protocol conformance
- ✅ Save/fetch/delete operations
- ✅ Predicate filtering
- ✅ Date-based queries
- ✅ Error handling
- ✅ @MainActor thread safety
- ✅ Model conversions

---

## 🔤 TIER 2a - Domain State Enums

**Priority**: MEDIUM | **Effort**: MEDIUM | **Est. Lines**: 1200+

### Target Files (10 enum files)
```
HomeDomainState                 SettingsDomainState
ForYouDomainState              ArticleDetailDomainState
FeedDomainState                SummarizationDomainState
BookmarksDomainState           PaywallDomainState
SearchDomainState              AuthDomainState
```

### Test Template

```swift
// File: PulseTests/{Feature}/Domain/{Feature}DomainStateTests.swift

@Suite("{Feature}DomainState Tests")
struct FeatureDomainStateTests {
    @Test("Initial idle state") {
        // Test .idle case
    }

    @Test("Loading state with progress") {
        // Test .loading(isLoading: true)
    }

    @Test("Success state with data") {
        // Test .success(data: [...])
    }

    @Test("Error state with message") {
        // Test .error(message: String)
    }

    @Test("States are equatable") {
        // Test equality comparisons
    }

    @Test("Associated values preserved") {
        // Test data integrity
    }
}
```

### Coverage Pattern
- ✅ Each enum case initialization
- ✅ Associated value storage
- ✅ Equatable conformance
- ✅ Inequality testing
- ✅ Edge cases (nil values, empty arrays)

---

## 🎬 TIER 2b - Domain Action Enums

**Priority**: MEDIUM | **Effort**: MEDIUM | **Est. Lines**: 1000+

### Target Files (8 enum files)
```
HomeDomainAction               ArticleDetailDomainAction
FeedDomainAction              SummarizationDomainAction
BookmarksDomainAction         PaywallDomainAction
SearchDomainAction            AuthDomainAction
```

### Test Template

```swift
// File: PulseTests/{Feature}/Domain/{Feature}DomainActionTests.swift

@Suite("{Feature}DomainAction Tests")
struct FeatureDomainActionTests {
    @Test("loadData action with parameters") {
        // Test .loadData(page: 1)
    }

    @Test("userTap action") {
        // Test .userTap(item)
    }

    @Test("success action with result") {
        // Test .success(data)
    }

    @Test("failure action with error") {
        // Test .failure(error)
    }

    @Test("Actions are equatable") {
        // Test equality
    }
}
```

---

## 📸 TIER 2c - View Snapshots

**Priority**: MEDIUM | **Effort**: LOW | **Est. Snapshots**: 40+

### Missing Snapshot Components (11 files)

**Home Feature** (4 components):
- `Home/ArticleRowView`
- `Home/BreakingNewsCard`
- `Home/ArticleSkeletonView`
- `Home/ShareSheet`

**Settings Feature** (3 components):
- `Settings/SettingsAccountSection`
- `Settings/SettingsMutedContentSection`
- `Settings/SettingsPremiumSection`

**Design System** (3 components):
- `Configs/DesignSystem/CachedAsyncImage`
- `Configs/DesignSystem/SwipeBackGesture`
- `Configs/DesignSystem/GlassModifiers`

### Test Template

```swift
// File: PulseSnapshotTests/{Feature}/View/{Component}SnapshotTests.swift

import SnapshotTesting
@testable import Pulse

@Suite("{Component} Snapshot Tests")
struct ComponentSnapshotTests {
    @Test("Renders with typical content") {
        let view = ComponentView(/* args */)
        assertSnapshot(of: view, as: .image)
    }

    @Test("Dark mode variant") {
        let view = ComponentView(/* args */)
        assertSnapshot(of: view, as: .image(trait: .dark))
    }

    @Test("Accessibility size variant") {
        let view = ComponentView(/* args */)
        assertSnapshot(of: view, as: .image(trait: .accessibilityMedium))
    }
}
```

---

## 🎨 TIER 3a - Design System

**Priority**: LOW | **Effort**: LOW | **Est. Lines**: 200+

### Target Files (3 files)
- `Pulse/Configs/DesignSystem/ColorSystem.swift`
- `Pulse/Configs/DesignSystem/Typography.swift`
- `Pulse/Configs/DesignSystem/DesignTokens.swift`

### Test Template

```swift
// File: PulseTests/Configs/DesignSystem/DesignSystemTests.swift

@Suite("ColorSystem Tests")
struct ColorSystemTests {
    @Test("All colors are defined") {
        #expect(ColorSystem.primary != nil)
        #expect(ColorSystem.secondary != nil)
    }

    @Test("Light/dark mode variants") {
        // Test color adaptation
    }

    @Test("Contrast ratios meet WCAG AA") {
        // Test accessibility
    }
}

@Suite("Typography Tests")
struct TypographyTests {
    @Test("Font sizes are reasonable") {
        #expect(Typography.headline.size > 0)
        #expect(Typography.body.size > 0)
    }

    @Test("Line heights are set") {
        // Verify line height values
    }
}

@Suite("DesignTokens Tests")
struct DesignTokensTests {
    @Test("Spacing scale is consistent") {
        // Test spacing arithmetic
    }

    @Test("Border radius definitions") {
        // Test radius values
    }
}
```

---

## 📦 TIER 3b - Model Classes

**Priority**: LOW | **Effort**: LOW | **Est. Lines**: 250+

### Target Files (4 files)
- `Pulse/Configs/Models/Article.swift`
- `Pulse/Configs/Models/GuardianResponse.swift`
- `Pulse/Configs/Models/UserPreferences.swift`
- `Pulse/Configs/Models/NewsResponse.swift`

### Test Template

```swift
// File: PulseTests/Configs/Models/ModelTests.swift

@Suite("Article Model Tests")
struct ArticleModelTests {
    @Test("Initialize with all properties") {
        let article = Article(/* params */)
        #expect(article.id != "")
        #expect(article.title != "")
    }

    @Test("Codable encoding/decoding") {
        let encoded = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(Article.self, from: encoded)
        #expect(decoded == article)
    }
}

@Suite("GuardianResponse Tests")
struct GuardianResponseTests {
    @Test("Parsing Guardian API response") {
        let json = // sample JSON
        let response = try JSONDecoder().decode(GuardianResponse.self, from: json)
        #expect(!response.response.results.isEmpty)
    }
}

@Suite("UserPreferences Tests")
struct UserPreferencesTests {
    @Test("Default preferences") {
        let prefs = UserPreferences.default
        #expect(prefs.theme == .automatic)
    }
}
```

---

## 🛠️ Implementation Strategy

### Quick Wins (Do First)
1. ✅ Complete TIER 1f - Storage Service (use MockStorageService as reference)
2. ⏭️ TIER 2a - State Enums (repetitive, can parallelize)
3. ⏭️ TIER 2b - Action Enums (similar pattern to states)
4. ⏭️ TIER 2c - Snapshots (use existing snapshot tests as templates)
5. ⏭️ TIER 3a - Design System (straightforward validation)
6. ⏭️ TIER 3b - Models (simple Codable tests)

### Command Reference

```bash
# Test individual tier
make test --filter "StorageServiceTests"
make test --filter "DomainStateTests"
make test --filter "SnapshotTests"

# Run all tests
make test

# Coverage report
make coverage
```

---

## 📊 Final Coverage Projection

```
TIER 1 (Services):      ✅ 100% (5/5 complete)
TIER 2 (Domain):        🔄 30% (1/3 in progress)
TIER 3 (Presentation):  ⏳ 0% (0/3 pending)

Overall Progress:       45% (5/11 complete)
Estimated Remaining:    ~2000+ test cases
Lines of Test Code:     ~3500+ written so far
```

---

## 📝 Notes

### Patterns to Follow
- Use `@MainActor` for SwiftUI/UI-related tests
- Mock external dependencies (API, storage)
- Keep assertions focused (one behavior per test)
- Use descriptive test names (arrange/act/assert)
- Include both happy path and error scenarios

### Common Pitfalls to Avoid
- ❌ Tests that depend on order
- ❌ Tests that aren't isolated
- ❌ Hardcoded test data (use mocks)
- ❌ Incomplete error coverage
- ❌ Missing edge cases

### Resources
- Existing test patterns: `PulseTests/Home/Domain/HomeViewStateReducerTests.swift`
- Mock services: `Pulse/Configs/Mocks/MockNewsService.swift`
- Test helpers: `PulseTests/TestHelpers.swift`

---

**Last Updated**: 2026-01-19
**Total Lines Written**: ~3500+
**Test Files Created**: 6
**Remaining Work**: 6 tiers
**Estimated Completion**: 8-12 hours

Happy testing! 🚀
