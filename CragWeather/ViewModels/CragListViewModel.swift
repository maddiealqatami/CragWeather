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

        let filtered = crags
            .filter { !$0.isBoulderCrag }
            .filter { activeFilters.matches($0) }

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

    func refreshRegion(modelContext: ModelContext, region: String) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await syncCoordinator.syncCrags(forRegion: region, modelContext: modelContext)
    }

    func refreshFavorites(modelContext: ModelContext, crags: [Crag]) async {
        let favorites = crags.filter { $0.isFavorite && !$0.isBoulderCrag }
        guard !favorites.isEmpty else { return }

        isRefreshing = true
        defer { isRefreshing = false }
        await syncCoordinator.refreshWeather(for: favorites, modelContext: modelContext)
    }
}
