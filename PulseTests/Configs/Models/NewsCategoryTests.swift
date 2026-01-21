import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("NewsCategory Tests")
struct NewsCategoryTests {
    // MARK: - All Categories Tests

    @Test("All seven categories exist with unique raw values")
    func allCategoriesExistWithUniqueRawValues() {
        #expect(NewsCategory.allCases.count == 7)
        let rawValues = NewsCategory.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        #expect(rawValues.count == uniqueRawValues.count)
    }

    // MARK: - Category Properties Tests (Consolidated)

    @Test(
        "Each category has correct icon, color, API parameter, and guardian section",
        arguments: [
            (NewsCategory.world, "globe", Color.blue, "general", "world"),
            (NewsCategory.business, "chart.line.uptrend.xyaxis", Color.green, "business", "business"),
            (NewsCategory.technology, "cpu", Color.purple, "technology", "technology"),
            (NewsCategory.science, "atom", Color.orange, "science", "science"),
            (NewsCategory.health, "heart.text.square", Color.red, "health", "society"),
            (NewsCategory.sports, "sportscourt", Color.cyan, "sports", "sport"),
            (NewsCategory.entertainment, "film", Color.pink, "entertainment", "culture"),
        ]
    )
    func categoryPropertiesAreCorrect(
        category: NewsCategory,
        expectedIcon: String,
        expectedColor: Color,
        expectedApiParam: String,
        expectedGuardianSection: String
    ) {
        #expect(category.icon == expectedIcon)
        #expect(category.color == expectedColor)
        #expect(category.apiParameter == expectedApiParam)
        #expect(category.guardianSection == expectedGuardianSection)
    }

    @Test("All categories have unique icons")
    func allCategoriesHaveUniqueIcons() {
        let icons = NewsCategory.allCases.map { $0.icon }
        let uniqueIcons = Set(icons)
        #expect(icons.count == uniqueIcons.count)
    }

    // MARK: - fromGuardianSection Tests (Consolidated)

    @Test(
        "Guardian section maps to correct category",
        arguments: [
            // World mappings
            ("world", NewsCategory.world),
            ("uk-news", NewsCategory.world),
            ("us-news", NewsCategory.world),
            ("australia-news", NewsCategory.world),
            // Business mappings
            ("business", NewsCategory.business),
            ("money", NewsCategory.business),
            // Technology
            ("technology", NewsCategory.technology),
            // Science
            ("science", NewsCategory.science),
            // Health mappings
            ("society", NewsCategory.health),
            ("healthcare-network", NewsCategory.health),
            // Sports mappings
            ("sport", NewsCategory.sports),
            ("football", NewsCategory.sports),
            // Entertainment mappings
            ("culture", NewsCategory.entertainment),
            ("film", NewsCategory.entertainment),
            ("music", NewsCategory.entertainment),
            ("books", NewsCategory.entertainment),
            ("tv-and-radio", NewsCategory.entertainment),
            ("stage", NewsCategory.entertainment),
        ]
    )
    func guardianSectionMapsToCategory(section: String, expectedCategory: NewsCategory) {
        #expect(NewsCategory.fromGuardianSection(section) == expectedCategory)
    }

    @Test(
        "Unknown guardian section defaults to world",
        arguments: ["unknown-section", "", "environment", "politics", "opinion"]
    )
    func unknownGuardianSectionDefaultsToWorld(section: String) {
        #expect(NewsCategory.fromGuardianSection(section) == .world)
    }

    @Test(
        "Guardian section matching is case insensitive",
        arguments: [
            ("WORLD", NewsCategory.world),
            ("World", NewsCategory.world),
            ("TECHNOLOGY", NewsCategory.technology),
            ("Sport", NewsCategory.sports),
        ]
    )
    func caseInsensitiveSectionMatching(section: String, expectedCategory: NewsCategory) {
        #expect(NewsCategory.fromGuardianSection(section) == expectedCategory)
    }

    // MARK: - Display Name & Identifiable Tests

    @Test("All categories have non-empty display names and id equals raw value")
    func displayNamesAndIdentifiable() {
        for category in NewsCategory.allCases {
            #expect(!category.displayName.isEmpty)
            #expect(category.id == category.rawValue)
        }
    }

    // MARK: - Codable Tests

    @Test("All categories can be encoded and decoded")
    func categoryCanBeEncodedAndDecoded() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for category in NewsCategory.allCases {
            let encoded = try encoder.encode(category)
            let decoded = try decoder.decode(NewsCategory.self, from: encoded)
            #expect(decoded == category)
        }
    }
}
