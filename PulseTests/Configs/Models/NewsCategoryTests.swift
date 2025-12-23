import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("NewsCategory Tests")
struct NewsCategoryTests {
    // MARK: - All Categories Tests

    @Test("All seven categories exist")
    func allSevenCategoriesExist() {
        #expect(NewsCategory.allCases.count == 7)
    }

    @Test("All categories have unique raw values")
    func allCategoriesHaveUniqueRawValues() {
        let rawValues = NewsCategory.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        #expect(rawValues.count == uniqueRawValues.count)
    }

    // MARK: - Icon Tests

    @Test("All categories have unique icons")
    func allCategoriesHaveUniqueIcons() {
        let icons = NewsCategory.allCases.map { $0.icon }
        let uniqueIcons = Set(icons)
        #expect(icons.count == uniqueIcons.count)
    }

    @Test("World category has globe icon")
    func worldHasGlobeIcon() {
        #expect(NewsCategory.world.icon == "globe")
    }

    @Test("Business category has chart icon")
    func businessHasChartIcon() {
        #expect(NewsCategory.business.icon == "chart.line.uptrend.xyaxis")
    }

    @Test("Technology category has cpu icon")
    func technologyHasCpuIcon() {
        #expect(NewsCategory.technology.icon == "cpu")
    }

    @Test("Science category has atom icon")
    func scienceHasAtomIcon() {
        #expect(NewsCategory.science.icon == "atom")
    }

    @Test("Health category has heart icon")
    func healthHasHeartIcon() {
        #expect(NewsCategory.health.icon == "heart.text.square")
    }

    @Test("Sports category has sportscourt icon")
    func sportsHasSportscourtIcon() {
        #expect(NewsCategory.sports.icon == "sportscourt")
    }

    @Test("Entertainment category has film icon")
    func entertainmentHasFilmIcon() {
        #expect(NewsCategory.entertainment.icon == "film")
    }

    // MARK: - Color Tests

    @Test("All categories have colors")
    func allCategoriesHaveColors() {
        for category in NewsCategory.allCases {
            // Just verify we can access the color without crash
            _ = category.color
        }
    }

    @Test("World category is blue")
    func worldIsBlue() {
        #expect(NewsCategory.world.color == .blue)
    }

    @Test("Business category is green")
    func businessIsGreen() {
        #expect(NewsCategory.business.color == .green)
    }

    @Test("Technology category is purple")
    func technologyIsPurple() {
        #expect(NewsCategory.technology.color == .purple)
    }

    // MARK: - API Parameter Tests

    @Test("World maps to general")
    func worldMapsToGeneral() {
        #expect(NewsCategory.world.apiParameter == "general")
    }

    @Test("Business maps to business")
    func businessMapsToBusiness() {
        #expect(NewsCategory.business.apiParameter == "business")
    }

    @Test("Technology maps to technology")
    func technologyMapsToTechnology() {
        #expect(NewsCategory.technology.apiParameter == "technology")
    }

    @Test("Science maps to science")
    func scienceMapsToScience() {
        #expect(NewsCategory.science.apiParameter == "science")
    }

    @Test("Health maps to health")
    func healthMapsToHealth() {
        #expect(NewsCategory.health.apiParameter == "health")
    }

    @Test("Sports maps to sports")
    func sportsMapsToSports() {
        #expect(NewsCategory.sports.apiParameter == "sports")
    }

    @Test("Entertainment maps to entertainment")
    func entertainmentMapsToEntertainment() {
        #expect(NewsCategory.entertainment.apiParameter == "entertainment")
    }

    // MARK: - Guardian Section Tests

    @Test("World guardian section is world")
    func worldGuardianSectionIsWorld() {
        #expect(NewsCategory.world.guardianSection == "world")
    }

    @Test("Business guardian section is business")
    func businessGuardianSectionIsBusiness() {
        #expect(NewsCategory.business.guardianSection == "business")
    }

    @Test("Technology guardian section is technology")
    func technologyGuardianSectionIsTechnology() {
        #expect(NewsCategory.technology.guardianSection == "technology")
    }

    @Test("Science guardian section is science")
    func scienceGuardianSectionIsScience() {
        #expect(NewsCategory.science.guardianSection == "science")
    }

    @Test("Health guardian section maps to society")
    func healthGuardianSectionIsSociety() {
        #expect(NewsCategory.health.guardianSection == "society")
    }

    @Test("Sports guardian section maps to sport (singular)")
    func sportsGuardianSectionIsSport() {
        #expect(NewsCategory.sports.guardianSection == "sport")
    }

    @Test("Entertainment guardian section maps to culture")
    func entertainmentGuardianSectionIsCulture() {
        #expect(NewsCategory.entertainment.guardianSection == "culture")
    }

    // MARK: - fromGuardianSection Tests

    @Test("world section returns world category")
    func worldSectionReturnsWorld() {
        #expect(NewsCategory.fromGuardianSection("world") == .world)
    }

    @Test("uk-news section returns world category")
    func ukNewsSectionReturnsWorld() {
        #expect(NewsCategory.fromGuardianSection("uk-news") == .world)
    }

    @Test("us-news section returns world category")
    func usNewsSectionReturnsWorld() {
        #expect(NewsCategory.fromGuardianSection("us-news") == .world)
    }

    @Test("australia-news section returns world category")
    func australiaNewsSectionReturnsWorld() {
        #expect(NewsCategory.fromGuardianSection("australia-news") == .world)
    }

    @Test("business section returns business category")
    func businessSectionReturnsBusiness() {
        #expect(NewsCategory.fromGuardianSection("business") == .business)
    }

    @Test("money section returns business category")
    func moneySectionReturnsBusiness() {
        #expect(NewsCategory.fromGuardianSection("money") == .business)
    }

    @Test("technology section returns technology category")
    func technologySectionReturnsTechnology() {
        #expect(NewsCategory.fromGuardianSection("technology") == .technology)
    }

    @Test("science section returns science category")
    func scienceSectionReturnsScience() {
        #expect(NewsCategory.fromGuardianSection("science") == .science)
    }

    @Test("society section returns health category")
    func societySectionReturnsHealth() {
        #expect(NewsCategory.fromGuardianSection("society") == .health)
    }

    @Test("healthcare-network section returns health category")
    func healthcareNetworkSectionReturnsHealth() {
        #expect(NewsCategory.fromGuardianSection("healthcare-network") == .health)
    }

    @Test("sport section returns sports category")
    func sportSectionReturnsSports() {
        #expect(NewsCategory.fromGuardianSection("sport") == .sports)
    }

    @Test("football section returns sports category")
    func footballSectionReturnsSports() {
        #expect(NewsCategory.fromGuardianSection("football") == .sports)
    }

    @Test("culture section returns entertainment category")
    func cultureSectionReturnsEntertainment() {
        #expect(NewsCategory.fromGuardianSection("culture") == .entertainment)
    }

    @Test("film section returns entertainment category")
    func filmSectionReturnsEntertainment() {
        #expect(NewsCategory.fromGuardianSection("film") == .entertainment)
    }

    @Test("music section returns entertainment category")
    func musicSectionReturnsEntertainment() {
        #expect(NewsCategory.fromGuardianSection("music") == .entertainment)
    }

    @Test("books section returns entertainment category")
    func booksSectionReturnsEntertainment() {
        #expect(NewsCategory.fromGuardianSection("books") == .entertainment)
    }

    @Test("tv-and-radio section returns entertainment category")
    func tvAndRadioSectionReturnsEntertainment() {
        #expect(NewsCategory.fromGuardianSection("tv-and-radio") == .entertainment)
    }

    @Test("stage section returns entertainment category")
    func stageSectionReturnsEntertainment() {
        #expect(NewsCategory.fromGuardianSection("stage") == .entertainment)
    }

    @Test("Unknown section returns nil")
    func unknownSectionReturnsNil() {
        #expect(NewsCategory.fromGuardianSection("unknown-section") == nil)
    }

    @Test("Empty section returns nil")
    func emptySectionReturnsNil() {
        #expect(NewsCategory.fromGuardianSection("") == nil)
    }

    @Test("Case insensitive section matching")
    func caseInsensitiveSectionMatching() {
        #expect(NewsCategory.fromGuardianSection("WORLD") == .world)
        #expect(NewsCategory.fromGuardianSection("World") == .world)
        #expect(NewsCategory.fromGuardianSection("TECHNOLOGY") == .technology)
        #expect(NewsCategory.fromGuardianSection("Sport") == .sports)
    }

    // MARK: - Display Name Tests

    @Test("All categories have display names")
    func allCategoriesHaveDisplayNames() {
        for category in NewsCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    // MARK: - Identifiable Tests

    @Test("Category id equals raw value")
    func categoryIdEqualsRawValue() {
        for category in NewsCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }

    // MARK: - Codable Tests

    @Test("Category can be encoded and decoded")
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
