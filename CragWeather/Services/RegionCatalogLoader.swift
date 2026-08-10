//
//  RegionCatalogLoader.swift
//  CragWeather
//

import Foundation
import SwiftData

struct RegionCatalogEntry: Decodable {
    let name: String
    let latitude: Double
    let longitude: Double
    let elevationMeters: Double?
}

enum RegionCatalogLoader {
    static func loadEntries() -> [RegionCatalogEntry] {
        guard let url = Bundle.main.url(forResource: "ColoradoRegions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([RegionCatalogEntry].self, from: data) else {
            return []
        }

        return entries.filter { entry in
            !CragExclusion.isBoulderArea(pathTokens: ["USA", "Colorado", entry.name], name: entry.name, region: entry.name)
        }
    }

    /// Ensures bundled region metadata exists in SwiftData and backfills missing elevations.
    static func syncBundledMetadata(modelContext: ModelContext) {
        let entries = loadEntries()
        guard !entries.isEmpty else { return }

        let existing = (try? modelContext.fetch(FetchDescriptor<RegionSummary>())) ?? []
        let existingByName = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })

        for entry in entries {
            if let summary = existingByName[entry.name] {
                summary.centroidLatitude = entry.latitude
                summary.centroidLongitude = entry.longitude
                if summary.representativeElevationMeters == nil {
                    summary.representativeElevationMeters = entry.elevationMeters
                }
            } else {
                let summary = RegionSummary(
                    name: entry.name,
                    centroidLatitude: entry.latitude,
                    centroidLongitude: entry.longitude,
                    representativeElevationMeters: entry.elevationMeters
                )
                modelContext.insert(summary)
            }
        }

        try? modelContext.save()
    }
}
