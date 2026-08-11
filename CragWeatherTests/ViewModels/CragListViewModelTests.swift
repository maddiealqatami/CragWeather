//
//  CragListViewModelTests.swift
//  CragWeatherTests
//

import Testing
@testable import CragWeather

@MainActor
struct CragListViewModelTests {
    private let viewModel = CragListViewModel()

    private var lowScoreCrag: Crag {
        CragFixtures.sportCrag(openBetaId: "low", name: "Beta Crag", cachedScore: 40)
    }

    private var highScoreCrag: Crag {
        CragFixtures.sportCrag(openBetaId: "high", name: "Alpha Crag", cachedScore: 90)
    }

    private var favoriteCrag: Crag {
        CragFixtures.sportCrag(
            openBetaId: "fav",
            name: "Favorite Crag",
            isFavorite: true,
            cachedScore: 70
        )
    }

    @Test func sortsByTodayScoreDescending() {
        viewModel.sortOption = .todayScore
        let result = viewModel.filteredAndSorted([lowScoreCrag, highScoreCrag])
        #expect(result.map(\.name) == ["Alpha Crag", "Beta Crag"])
    }

    @Test func sortsByName() {
        viewModel.sortOption = .name
        let result = viewModel.filteredAndSorted([highScoreCrag, lowScoreCrag])
        #expect(result.map(\.name) == ["Alpha Crag", "Beta Crag"])
    }

    @Test func appliesSearchFilter() {
        viewModel.filters.searchText = "alpha"
        let result = viewModel.filteredAndSorted([lowScoreCrag, highScoreCrag])
        #expect(result.count == 1)
        #expect(result.first?.name == "Alpha Crag")
    }

    @Test func favoritesTabUsesSeparateSearchText() {
        viewModel.favoritesSearchText = "favorite"
        let result = viewModel.filteredAndSorted([favoriteCrag, highScoreCrag], favoritesOnly: true)
        #expect(result.count == 1)
        #expect(result.first?.isFavorite == true)
    }

    @Test func excludesBoulderCragsFromResults() {
        let boulder = CragFixtures.boulderOnlyCrag()
        let result = viewModel.filteredAndSorted([boulder, highScoreCrag])
        #expect(result.count == 1)
        #expect(result.first?.name == "Alpha Crag")
    }

    @Test func sanitizeFiltersRemovesInvalidOptions() {
        viewModel.filters.climbType = .alpine
        viewModel.filters.elevationBand = .alpine
        viewModel.sanitizeFilters(for: CragFilterOptions(
            climbTypes: [.sport],
            elevationBands: [.mid],
            aspects: [.south],
            rockTypes: [.granite]
        ))
        #expect(viewModel.filters.climbType == nil)
        #expect(viewModel.filters.elevationBand == nil)
    }

    @Test func resetSearchClearsAppropriateField() {
        viewModel.filters.searchText = "test"
        viewModel.favoritesSearchText = "fav"
        viewModel.resetSearch(forFavoritesTab: false)
        #expect(viewModel.filters.searchText.isEmpty)
        #expect(viewModel.favoritesSearchText == "fav")

        viewModel.resetSearch(forFavoritesTab: true)
        #expect(viewModel.favoritesSearchText.isEmpty)
    }
}
