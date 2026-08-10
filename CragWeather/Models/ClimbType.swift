//
//  ClimbType.swift
//  CragWeather
//

import Foundation

enum ClimbType: String, CaseIterable, Identifiable, Codable {
    case sport
    case trad
    case boulder
    case alpine
    case topRope = "tr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sport: return "Sport"
        case .trad: return "Trad"
        case .boulder: return "Boulder"
        case .alpine: return "Alpine"
        case .topRope: return "Top Rope"
        }
    }

    static func fromOpenBeta(type: OpenBetaClimbType) -> [ClimbType] {
        var types: [ClimbType] = []
        if type.sport == true { types.append(.sport) }
        if type.trad == true { types.append(.trad) }
        if type.bouldering == true { types.append(.boulder) }
        if type.alpine == true { types.append(.alpine) }
        if type.tr == true { types.append(.topRope) }
        return types
    }
}
