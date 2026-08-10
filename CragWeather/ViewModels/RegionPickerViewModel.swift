//
//  RegionPickerViewModel.swift
//  CragWeather
//

import Foundation

@MainActor
@Observable
final class RegionPickerViewModel {
    let syncCoordinator: CragSyncCoordinator
    var searchText: String = ""

    init(syncCoordinator: CragSyncCoordinator) {
        self.syncCoordinator = syncCoordinator
    }

    func sortedRegions(_ regions: [RegionSummary]) -> [RegionSummary] {
        regions
            .filter(\.isEligibleForPicker)
            .sorted { lhs, rhs in
                let lhsScore = lhs.cachedScore ?? -1
                let rhsScore = rhs.cachedScore ?? -1
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func displayedRegions(_ regions: [RegionSummary]) -> [RegionSummary] {
        let sorted = sortedRegions(regions)
        guard !searchText.isEmpty else { return sorted }
        let query = searchText.lowercased()
        return sorted.filter { $0.name.lowercased().contains(query) }
    }
}
