//
//  CragListViewModel.swift
//  CragWeather
//

import Foundation
import SwiftData

@MainActor
@Observable
final class CragListViewModel {
    var filters = CragFilters()
    var sortOption: CragSortOption = .todayScore
    var showFavoritesOnly = false
    var isRefreshing = false

    let syncCoordinator = CragSyncCoordinator()

    func filteredAndSorted(_ crags: [Crag]) -> [Crag] {
        var activeFilters = filters
        if showFavoritesOnly {
            activeFilters.favoritesOnly = true
        }

        let filtered = crags.filter { activeFilters.matches($0) }

        return filtered.sorted { lhs, rhs in
            switch sortOption {
            case .todayScore:
                return (lhs.cachedScore ?? -1) > (rhs.cachedScore ?? -1)
            case .bestScore:
                return (lhs.bestForecastScore ?? -1) > (rhs.bestForecastScore ?? -1)
            case .name:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .elevation:
                return (lhs.elevationFeet ?? 0) > (rhs.elevationFeet ?? 0)
            }
        }
    }

    var availableRegions: [String] {
        []
    }

    func regions(from crags: [Crag]) -> [String] {
        Array(Set(crags.map(\.region))).sorted()
    }

    func refresh(modelContext: ModelContext, crags: [Crag]) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await syncCoordinator.refreshWeather(for: crags, modelContext: modelContext, limit: 200)
    }
}
