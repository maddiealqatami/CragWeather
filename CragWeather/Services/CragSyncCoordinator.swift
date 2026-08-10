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
    private var weatherService = WeatherService()
    private let scoringService = ConditionsScoringService()

    func syncIfNeeded(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Crag>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        if existingCount == 0 {
            await performFullSync(modelContext: modelContext)
        } else {
            syncedCragCount = existingCount
            phase = .complete
            await refreshWeather(for: Array((try? modelContext.fetch(descriptor)) ?? []), modelContext: modelContext, limit: 100)
        }
    }

    func performFullSync(modelContext: ModelContext) async {
        phase = .syncingCrags(current: 0)

        do {
            let dtos = try await openBetaService.fetchColoradoCrags { [weak self] count in
                Task { @MainActor in
                    self?.phase = .syncingCrags(current: count)
                }
            }

            let enrichment = CragEnrichmentLoader.loadEntries()
            var crags: [Crag] = []

            for dto in dtos {
                let crag = Crag(
                    openBetaId: dto.openBetaId,
                    name: dto.name,
                    region: dto.region,
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

            let elevationInputs = crags.map { (id: $0.openBetaId, lat: $0.latitude, lng: $0.longitude) }
            let elevations = try await weatherService.fetchElevations(for: elevationInputs)
            for crag in crags {
                if let elevation = elevations[crag.openBetaId] {
                    crag.elevationMeters = elevation
                }
            }
            try modelContext.save()

            phase = .syncingWeather
            await refreshWeather(for: crags, modelContext: modelContext, limit: min(200, crags.count))
            phase = .complete
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func refreshWeather(for crags: [Crag], modelContext: ModelContext, limit: Int? = nil) async {
        let targetCrags: [Crag]
        if let limit {
            let favorites = crags.filter(\.isFavorite)
            let nonFavorites = crags.filter { !$0.isFavorite }.sorted { ($0.cachedScore ?? 0) > ($1.cachedScore ?? 0) }
            var selected = favorites
            for crag in nonFavorites where selected.count < limit {
                if !selected.contains(where: { $0.openBetaId == crag.openBetaId }) {
                    selected.append(crag)
                }
            }
            targetCrags = selected
        } else {
            targetCrags = crags
        }

        guard !targetCrags.isEmpty else { return }

        do {
            let batches = try await weatherService.fetchForecasts(for: targetCrags)
            for batch in batches {
                guard let crag = targetCrags.first(where: { $0.openBetaId == batch.cragId }) else { continue }
                updateForecasts(for: crag, days: batch.days, modelContext: modelContext)
            }
            try modelContext.save()
        } catch {
            if case .complete = phase {} else {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func refreshAllWeather(modelContext: ModelContext) async {
        phase = .syncingWeather
        let descriptor = FetchDescriptor<Crag>()
        guard let crags = try? modelContext.fetch(descriptor) else {
            phase = .failed("Could not load crags.")
            return
        }
        await refreshWeather(for: crags, modelContext: modelContext)
        phase = .complete
    }

    private func updateForecasts(for crag: Crag, days: [DayForecastInput], modelContext: ModelContext) {
        for existing in crag.forecasts {
            modelContext.delete(existing)
        }
        crag.forecasts.removeAll()
        let calendar = Calendar.current
        var todayScore: Double?

        for day in days {
            let forecast = scoringService.makeForecast(
                cragId: crag.openBetaId,
                day: day,
                elevationMeters: crag.elevationMeters,
                aspect: crag.aspect,
                rockType: crag.rockType
            )
            modelContext.insert(forecast)
            crag.forecasts.append(forecast)

            if calendar.isDateInToday(day.date) {
                todayScore = forecast.conditionsScore
            }
        }

        if let todayScore {
            crag.cachedScore = todayScore
            crag.cachedScoreDate = .now
        } else if let best = crag.forecasts.first?.conditionsScore {
            crag.cachedScore = best
            crag.cachedScoreDate = .now
        }
    }
}
