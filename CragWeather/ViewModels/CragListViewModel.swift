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
    var favoritesSearchText = ""
    var sortOption: CragSortOption = .todayScore
    var isRefreshing = false

    let syncCoordinator = CragSyncCoordinator()

    func filteredAndSorted(_ crags: [Crag], favoritesOnly: Bool = false) -> [Crag] {
        var activeFilters = filters
        if favoritesOnly {
            activeFilters.favoritesOnly = true
            activeFilters.searchText = favoritesSearchText
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

    func resetSearch(forFavoritesTab favoritesTab: Bool) {
        if favoritesTab {
            favoritesSearchText = ""
        } else {
            filters.searchText = ""
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

    func sanitizeFilters(for options: CragFilterOptions) {
        if let climbType = filters.climbType, !options.climbTypes.contains(climbType) {
            filters.climbType = nil
        }
        if let elevationBand = filters.elevationBand, !options.elevationBands.contains(elevationBand) {
            filters.elevationBand = nil
        }
        if let aspect = filters.aspect, !options.aspects.contains(aspect) {
            filters.aspect = nil
        }
        if let rockType = filters.rockType, !options.rockTypes.contains(rockType) {
            filters.rockType = nil
        }
    }
}
