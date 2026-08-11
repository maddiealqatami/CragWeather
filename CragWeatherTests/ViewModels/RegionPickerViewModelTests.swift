//
//  RegionPickerViewModelTests.swift
//  CragWeatherTests
//

import Foundation
import Testing
@testable import CragWeather

@MainActor
struct RegionPickerViewModelTests {
    private let viewModel = RegionPickerViewModel(syncCoordinator: CragSyncCoordinator())

    @Test func sortsByScoreDescendingThenName() {
        let regions = [
            CragFixtures.regionSummary(name: "Zulu", cachedScore: 50),
            CragFixtures.regionSummary(name: "Alpha", cachedScore: 90),
            CragFixtures.regionSummary(name: "Bravo", cachedScore: 90)
        ]
        let sorted = viewModel.sortedRegions(regions)
        #expect(sorted.map(\.name) == ["Alpha", "Bravo", "Zulu"])
    }

    @Test func filtersIneligibleRegions() {
        let regions = [
            CragFixtures.regionSummary(name: "Visible", cragCount: 3),
            CragFixtures.regionSummary(name: "Hidden", cragCount: 0, lastCragSyncDate: .now)
        ]
        let sorted = viewModel.sortedRegions(regions)
        #expect(sorted.count == 1)
        #expect(sorted.first?.name == "Visible")
    }

    @Test func searchFiltersByName() {
        let regions = [
            CragFixtures.regionSummary(name: "Boulder"),
            CragFixtures.regionSummary(name: "Estes Park")
        ]
        viewModel.searchText = "estes"
        let displayed = viewModel.displayedRegions(regions)
        #expect(displayed.count == 1)
        #expect(displayed.first?.name == "Estes Park")
    }

    @Test func emptySearchShowsAllEligible() {
        viewModel.searchText = ""
        let regions = [
            CragFixtures.regionSummary(name: "Boulder"),
            CragFixtures.regionSummary(name: "Estes Park")
        ]
        #expect(viewModel.displayedRegions(regions).count == 2)
    }
}
