//
//  CragEnrichmentLoader.swift
//  CragWeather
//

import Foundation

struct CragEnrichmentEntry: Decodable {
    let name: String
    let openBetaId: String?
    let aspect: String?
    let rockType: String?
}

struct CragEnrichmentLoader {
    static func loadEntries() -> [CragEnrichmentEntry] {
        guard let url = Bundle.main.url(forResource: "CragEnrichment", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([CragEnrichmentEntry].self, from: data) else {
            return []
        }
        return entries
    }

    static func apply(to crag: Crag, entries: [CragEnrichmentEntry]) {
        let match = entries.first { entry in
            if let id = entry.openBetaId, id == crag.openBetaId { return true }
            return entry.name.caseInsensitiveCompare(crag.name) == .orderedSame
        }
        guard let match else { return }
        if let aspectRaw = match.aspect, let aspect = Aspect(rawValue: aspectRaw) {
            crag.aspect = aspect
        }
        if let rockRaw = match.rockType, let rock = RockType(rawValue: rockRaw) {
            crag.rockType = rock
        }
    }
}
