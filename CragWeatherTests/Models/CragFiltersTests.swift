//
//  CragFiltersTests.swift
//  CragWeatherTests
//

import Foundation
import Testing
@testable import CragWeather

struct CragFiltersTests {
    private let sportCrag = CragFixtures.sportCrag(
        name: "Eldorado Canyon",
        region: "Boulder",
        elevationMeters: 2100,
        climbTypes: [.sport, .trad],
        aspect: .south,
        rockType: .sandstone
    )

    private let alpineCrag = CragFixtures.sportCrag(
        openBetaId: "alpine-1",
        name: "Longs Peak",
        region: "Estes Park",
        elevationMeters: 3700,
        climbTypes: [.alpine],
        aspect: .east,
        rockType: .granite,
        isFavorite: true
    )

    @Test func defaultFiltersMatchSportCrag() {
        #expect(CragFilters().matches(sportCrag))
    }

    @Test func searchMatchesNameAndRegion() {
        var filters = CragFilters()
        filters.searchText = "eldorado"
        #expect(filters.matches(sportCrag))

        filters.searchText = "boulder"
        #expect(filters.matches(sportCrag))

        filters.searchText = "longs"
        #expect(!filters.matches(sportCrag))
    }

    @Test func climbTypeFilter() {
        var filters = CragFilters()
        filters.climbType = .sport
        #expect(filters.matches(sportCrag))
        #expect(!filters.matches(alpineCrag))

        filters.climbType = .boulder
        #expect(!filters.matches(sportCrag))
    }

    @Test func elevationBandFilter() {
        var filters = CragFilters()
        filters.elevationBand = .mid
        #expect(filters.matches(sportCrag))
        #expect(!filters.matches(alpineCrag))

        filters.elevationBand = .high
        #expect(!filters.matches(alpineCrag))

        filters.elevationBand = .alpine
        #expect(filters.matches(alpineCrag))
    }

    @Test func aspectAndRockTypeFilters() {
        var filters = CragFilters()
        filters.aspect = .south
        #expect(filters.matches(sportCrag))
        #expect(!filters.matches(alpineCrag))

        filters = CragFilters()
        filters.rockType = .granite
        #expect(!filters.matches(sportCrag))
        #expect(filters.matches(alpineCrag))
    }

    @Test func favoritesOnlyFilter() {
        var filters = CragFilters()
        filters.favoritesOnly = true
        #expect(!filters.matches(sportCrag))
        #expect(filters.matches(alpineCrag))
    }

    @Test func boulderCragsNeverMatch() {
        let boulder = CragFixtures.boulderOnlyCrag()
        #expect(!CragFilters().matches(boulder))
    }

    @Test func isActiveReflectsAppliedFilters() {
        #expect(!CragFilters().isActive)
        var filters = CragFilters()
        filters.searchText = "test"
        #expect(filters.isActive)
    }

    @Test func filterOptionsDerivedFromCragSet() {
        let options = CragFilterOptions.from(crags: [sportCrag, alpineCrag, CragFixtures.boulderOnlyCrag()])
        #expect(options.climbTypes.contains(.sport))
        #expect(options.climbTypes.contains(.alpine))
        #expect(!options.climbTypes.contains(.boulder))
        #expect(options.aspects.contains(.south))
        #expect(options.aspects.contains(.east))
        #expect(options.rockTypes.contains(.sandstone))
        #expect(options.rockTypes.contains(.granite))
        #expect(options.elevationBands.contains(.mid))
        #expect(options.elevationBands.contains(.alpine))
    }
}
