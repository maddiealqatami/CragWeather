//
//  CragExclusion.swift
//  CragWeather
//

import Foundation

enum CragExclusion {
    private static let ropedTypes: Set<ClimbType> = [.sport, .trad, .alpine, .topRope]

    static func shouldExclude(
        climbTypes: [ClimbType],
        pathTokens: [String] = [],
        name: String = "",
        region: String = ""
    ) -> Bool {
        if isBoulderArea(pathTokens: pathTokens, name: name, region: region) {
            return true
        }

        guard !climbTypes.isEmpty else { return false }

        if climbTypes.allSatisfy({ $0 == .boulder }) {
            return true
        }

        if climbTypes.contains(.boulder), !climbTypes.contains(where: { ropedTypes.contains($0) }) {
            return true
        }

        return false
    }

    static func isBoulderArea(pathTokens: [String], name: String = "", region: String = "") -> Bool {
        let candidates = pathTokens + [name, region]
        return candidates.contains { token in
            let lower = token.lowercased()
            return lower.contains("bouldering") || lower.hasSuffix(" boulders") || lower == "boulders"
        }
    }
}
