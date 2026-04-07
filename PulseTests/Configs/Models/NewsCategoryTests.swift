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
        "Each category has correct icon, color, and API parameter",
        arguments: [
            (NewsCategory.world, "globe", Color.blue, "general"),
            (NewsCategory.business, "chart.line.uptrend.xyaxis", Color.green, "business"),
            (NewsCategory.technology, "cpu", Color.purple, "technology"),
            (NewsCategory.science, "atom", Color.orange, "science"),
            (NewsCategory.health, "heart.text.square", Color.red, "health"),
            (NewsCategory.sports, "sportscourt", Color.cyan, "sports"),
            (NewsCategory.entertainment, "film", Color.pink, "entertainment"),
        ]
    )
    func categoryPropertiesAreCorrect(
        category: NewsCategory,
        expectedIcon: String,
        expectedColor: Color,
        expectedApiParam: String
    ) {
        #expect(category.icon == expectedIcon)
        #expect(category.color == expectedColor)
        #expect(category.apiParameter == expectedApiParam)
    }

    @Test("All categories have unique icons")
    func allCategoriesHaveUniqueIcons() {
        let icons = NewsCategory.allCases.map { $0.icon }
        let uniqueIcons = Set(icons)
        #expect(icons.count == uniqueIcons.count)
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
