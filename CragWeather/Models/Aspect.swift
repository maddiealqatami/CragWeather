//
//  Aspect.swift
//  CragWeather
//

import Foundation

enum Aspect: String, CaseIterable, Identifiable, Codable {
    case north = "N"
    case northeast = "NE"
    case east = "E"
    case southeast = "SE"
    case south = "S"
    case southwest = "SW"
    case west = "W"
    case northwest = "NW"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .north: return "North"
        case .northeast: return "Northeast"
        case .east: return "East"
        case .southeast: return "Southeast"
        case .south: return "South"
        case .southwest: return "Southwest"
        case .west: return "West"
        case .northwest: return "Northwest"
        }
    }

    /// Approximate sun exposure bonus (0–1) for afternoon climbing hours by season.
    func sunExposureBonus(month: Int) -> Double {
        let isWinter = month <= 3 || month >= 11
        switch self {
        case .south: return isWinter ? 1.0 : 0.7
        case .southeast, .southwest: return isWinter ? 0.85 : 0.75
        case .east: return isWinter ? 0.7 : 0.6
        case .west: return 0.5
        case .north, .northeast, .northwest: return isWinter ? 0.2 : 0.35
        }
    }
}

enum RockType: String, CaseIterable, Identifiable, Codable {
    case granite
    case sandstone
    case limestone
    case gneiss
    case quartzite
    case conglomerate

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    /// Multiplier applied to precipitation penalty (higher = dries slower).
    var rainSensitivity: Double {
        switch self {
        case .sandstone: return 1.5
        case .limestone: return 1.2
        case .conglomerate: return 1.1
        case .granite, .gneiss, .quartzite: return 1.0
        }
    }
}
