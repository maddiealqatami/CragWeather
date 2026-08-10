//
//  CragSyncCoordinator.swift
//  CragWeather
//

import Foundation
import SwiftData

enum SyncPhase: Equatable {
    case idle
    case syncingCrags(current: Int)
    case syncingElevations
    case syncingRegions
    case refreshingScores
    case syncingWeather
    case complete
    case failed(String)
}

@MainActor
@Observable
final class CragSyncCoordinator {
    var phase: SyncPhase = .idle
    var syncedCragCount: Int = 0

    private let openBetaService = OpenBetaService()
    private var weatherService = WeatherService.shared
    private let scoringService = ConditionsScoringService()
    private let regionScoringService = RegionScoringService()

    /// Launch sync: seed bundled regions, show picker immediately, refresh scores in background.
    func syncRegionsOnly(modelContext: ModelContext) async {
        purgeBoulderCrags(modelContext: modelContext)
        RegionCatalogLoader.syncBundledMetadata(modelContext: modelContext)

        let regions = (try? modelContext.fetch(FetchDescriptor<RegionSummary>())) ?? []
        guard !regions.isEmpty else {
            phase = .failed("No Colorado regions available.")
            return
        }

        phase = .complete

        await refreshRegionScoresIfNeeded(modelContext: modelContext)
        await refreshRegionMetadataIfNeeded(modelContext: modelContext)
    }

    /// Post-selection sync: fetch crags, elevations, and weather for one region.
    func syncCrags(forRegion region: String, modelContext: ModelContext) async {
        purgeBoulderCrags(modelContext: modelContext)

        let existingCrags = crags(forRegion: region, modelContext: modelContext)
        if existingCrags.isEmpty {
            await fetchAndStoreCrags(forRegion: region, modelContext: modelContext)
        } else {
            syncedCragCount = existingCrags.count
            updateRegionCragCount(region: region, modelContext: modelContext)
        }

        await refreshWeather(forRegion: region, modelContext: modelContext)
    }

    func purgeBoulderCrags(modelContext: ModelContext) {
        guard let crags = try? modelContext.fetch(FetchDescriptor<Crag>()) else { return }

        for crag in crags where crag.isBoulderCrag {
            for forecast in crag.forecasts {
                modelContext.delete(forecast)
            }
            modelContext.delete(crag)
        }

        try? modelContext.save()
    }

    private func fetchAndStoreCrags(forRegion region: String, modelContext: ModelContext) async {
        phase = .syncingCrags(current: 0)

        do {
            let dtos = try await openBetaService.fetchCrags(forRegion: region) { [weak self] count in
                self?.phase = .syncingCrags(current: count)
            }

            let enrichment = CragEnrichmentLoader.loadEntries()
            var crags: [Crag] = []

            for dto in dtos {
                let crag = Crag(
                    openBetaId: dto.openBetaId,
                    name: dto.name,
                    region: dto.region,
                    pathTokens: dto.pathTokens,
                    latitude: dto.latitude,
                    longitude: dto.longitude,
                    climbTypes: dto.climbTypes
                )
                CragEnrichmentLoader.apply(to: crag, entries: enrichment)
                crags.append(crag)
            }

            for crag in crags {
                modelContext.insert(crag)
            }
            try modelContext.save()

            syncedCragCount = crags.count
            phase = .syncingElevations

            let needsElevation = crags.filter { $0.elevationMeters == nil }
            if !needsElevation.isEmpty {
                let elevationInputs = needsElevation.map { (id: $0.openBetaId, lat: $0.latitude, lng: $0.longitude) }
                let elevations = try await weatherService.fetchElevations(for: elevationInputs)
                for crag in needsElevation {
                    if let elevation = elevations[crag.openBetaId] {
                        crag.elevationMeters = elevation
                    }
                }
                try modelContext.save()
            }

            updateRegionCragCount(region: region, modelContext: modelContext)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func refreshRegionScoresIfNeeded(modelContext: ModelContext) async {
        let regions = (try? modelContext.fetch(FetchDescriptor<RegionSummary>())) ?? []
        let needsScore = regions.filter(\.needsScoreRefresh)
        guard !needsScore.isEmpty else { return }

        phase = .refreshingScores
        do {
            try await regionScoringService.scoreRegions(needsScore, modelContext: modelContext)
        } catch {
            // Non-fatal: picker stays usable with cached or missing scores.
        }
        phase = .complete
    }

    private func refreshRegionMetadataIfNeeded(modelContext: ModelContext) async {
        let regions = (try? modelContext.fetch(FetchDescriptor<RegionSummary>())) ?? []
        guard regions.contains(where: \.needsMetadataRefresh) else { return }

        do {
            let regionDTOs = try await openBetaService.fetchColoradoRegions()
            try upsertRegionsFromAPI(regionDTOs, modelContext: modelContext, metadataSyncDate: .now)
        } catch {
            // Non-fatal: bundled catalog centroids remain usable.
        }
    }

    private func upsertRegionsFromAPI(
        _ regionDTOs: [OpenBetaRegionDTO],
        modelContext: ModelContext,
        metadataSyncDate: Date?
    ) throws {
        let existingRegions = (try? modelContext.fetch(FetchDescriptor<RegionSummary>())) ?? []
        let existingByName = Dictionary(uniqueKeysWithValues: existingRegions.map { ($0.name, $0) })
        let cragCounts = cragCountsByRegion(modelContext: modelContext)

        for dto in regionDTOs {
            let localCount = cragCounts[dto.name] ?? 0

            if let existing = existingByName[dto.name] {
                existing.centroidLatitude = dto.latitude
                existing.centroidLongitude = dto.longitude
                if localCount > 0 {
                    existing.cragCount = localCount
                }
                if let metadataSyncDate {
                    existing.lastMetadataSyncDate = metadataSyncDate
                }
            } else {
                let summary = RegionSummary(
                    name: dto.name,
                    centroidLatitude: dto.latitude,
                    centroidLongitude: dto.longitude,
                    cragCount: localCount,
                    lastMetadataSyncDate: metadataSyncDate
                )
                modelContext.insert(summary)
            }
        }

        try modelContext.save()
    }

    private func cragCountsByRegion(modelContext: ModelContext) -> [String: Int] {
        let allCrags = (try? modelContext.fetch(FetchDescriptor<Crag>())) ?? []
        var counts: [String: Int] = [:]
        for crag in allCrags where !crag.isBoulderCrag {
            counts[crag.region, default: 0] += 1
        }
        return counts
    }

    private func updateRegionCragCount(region: String, modelContext: ModelContext) {
        let count = crags(forRegion: region, modelContext: modelContext).count
        guard let regions = try? modelContext.fetch(FetchDescriptor<RegionSummary>()) else { return }
        if let summary = regions.first(where: { $0.name == region }) {
            summary.cragCount = count
            try? modelContext.save()
        }
    }

    private func crags(forRegion region: String, modelContext: ModelContext) -> [Crag] {
        let allCrags = (try? modelContext.fetch(FetchDescriptor<Crag>())) ?? []
        return allCrags.filter { !$0.isBoulderCrag && $0.region == region }
    }

    func refreshWeather(forRegion region: String, modelContext: ModelContext) async {
        let regionCrags = crags(forRegion: region, modelContext: modelContext)
        await refreshWeather(for: regionCrags, modelContext: modelContext)
    }

    func refreshWeather(for crags: [Crag], modelContext: ModelContext) async {
        let targetCrags = crags.filter { !$0.isBoulderCrag }
        guard !targetCrags.isEmpty else {
            if case .syncingCrags = phase {
                phase = .complete
            }
            return
        }

        phase = .syncingWeather

        do {
            let batches = try await weatherService.fetchForecasts(for: targetCrags)
            for batch in batches {
                guard let crag = targetCrags.first(where: { $0.openBetaId == batch.cragId }) else { continue }
                crag.applyForecastDays(batch.days, modelContext: modelContext, scoringService: scoringService)
                try modelContext.save()
            }
            phase = .complete
        } catch {
            // Non-fatal: crags remain visible; scores stay stale until next refresh.
            if case .syncingWeather = phase {
                phase = .complete
            }
        }
    }
}
