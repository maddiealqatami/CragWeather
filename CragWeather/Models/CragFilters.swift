//
//  CragFilters.swift
//  CragWeather
//

import Foundation

struct CragFilters: Equatable {
    var searchText: String = ""
    var climbType: ClimbType?
    var elevationBand: ElevationBand?
    var aspect: Aspect?
    var rockType: RockType?
    var favoritesOnly: Bool = false

    var isActive: Bool {
        !searchText.isEmpty ||
        climbType != nil ||
        elevationBand != nil ||
        aspect != nil ||
        rockType != nil ||
        favoritesOnly
    }

    func matches(_ crag: Crag) -> Bool {
        if crag.isBoulderCrag { return false }
        if favoritesOnly && !crag.isFavorite { return false }

        if let climbType {
            if climbType == .boulder { return false }
            if !crag.climbTypes.contains(climbType) { return false }
        }

        if let elevationBand {
            guard let feet = crag.elevationFeet else { return false }
            if !elevationBand.contains(feet) { return false }
        }

        if let aspect, crag.aspect != aspect { return false }

        if let rockType, crag.rockType != rockType { return false }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            if !crag.name.lowercased().contains(query) &&
                !crag.region.lowercased().contains(query) {
                return false
            }
        }

        return true
    }
}

enum ElevationBand: String, CaseIterable, Identifiable {
    case below6000 = "< 6,000 ft"
    case mid = "6,000–9,000 ft"
    case high = "9,000–12,000 ft"
    case alpine = "> 12,000 ft"

    var id: String { rawValue }

    func contains(_ feet: Int) -> Bool {
        switch self {
        case .below6000: return feet < 6000
        case .mid: return (6000...9000).contains(feet)
        case .high: return (9000...12000).contains(feet)
        case .alpine: return feet > 12000
        }
    }
}

enum CragSortOption: String, CaseIterable, Identifiable {
    case todayScore = "Today's Score"
    case bestScore = "Best in 5 Days"
    case name = "Name"
    case elevation = "Elevation"

    var id: String { rawValue }
}
