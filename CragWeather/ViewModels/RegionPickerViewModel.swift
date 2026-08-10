//
//  RegionPickerViewModel.swift
//  CragWeather
//

import Foundation

@MainActor
@Observable
final class RegionPickerViewModel {
    let syncCoordinator: CragSyncCoordinator

    init(syncCoordinator: CragSyncCoordinator) {
        self.syncCoordinator = syncCoordinator
    }

    func sortedRegions(_ regions: [RegionSummary]) -> [RegionSummary] {
        regions.sorted { lhs, rhs in
            let lhsScore = lhs.cachedScore ?? -1
            let rhsScore = rhs.cachedScore ?? -1
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
