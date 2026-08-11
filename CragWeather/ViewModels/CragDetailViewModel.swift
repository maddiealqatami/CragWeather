//
//  CragDetailViewModel.swift
//  CragWeather
//

import Foundation
import SwiftData

@MainActor
@Observable
final class CragDetailViewModel {
    var isLoading = false
    var errorMessage: String?
    var scoreBreakdowns: [Date: ScoreBreakdown] = [:]

    private var weatherService = WeatherService.shared
    private let scoringService = ConditionsScoringService()

    func loadForecast(for crag: Crag, modelContext: ModelContext) async {
        if applyStoredForecastsIfAvailable(for: crag, modelContext: modelContext) {
            return
        }

        // Region weather sync may still be writing forecasts for this crag.
        try? await Task.sleep(nanoseconds: 750_000_000)
        if applyStoredForecastsIfAvailable(for: crag, modelContext: modelContext) {
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let days = try await weatherService.fetchForecast(for: crag)
            crag.applyForecastDays(days, modelContext: modelContext, scoringService: scoringService)
            try modelContext.save()
            computeBreakdowns(for: crag)
        } catch {
            if applyStoredForecastsIfAvailable(for: crag, modelContext: modelContext) {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    private func applyStoredForecastsIfAvailable(for crag: Crag, modelContext: ModelContext) -> Bool {
        let storedForecasts = fetchStoredForecasts(for: crag, modelContext: modelContext)
        guard !storedForecasts.isEmpty else { return false }

        if crag.forecasts.isEmpty {
            crag.forecasts = storedForecasts
        }

        errorMessage = nil
        crag.updateCachedScoreFromForecasts()
        try? modelContext.save()
        computeBreakdowns(for: crag)
        return true
    }

    private func fetchStoredForecasts(for crag: Crag, modelContext: ModelContext) -> [CragForecast] {
        if !crag.forecasts.isEmpty {
            return crag.forecasts.sorted { $0.date < $1.date }
        }

        let cragId = crag.openBetaId
        var descriptor = FetchDescriptor<CragForecast>(
            predicate: #Predicate { $0.cragId == cragId }
        )
        descriptor.sortBy = [SortDescriptor(\.date)]
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func breakdown(for forecast: CragForecast, crag: Crag) -> ScoreBreakdown {
        if let cached = scoreBreakdowns[forecast.date] {
            return cached
        }
        let day = DayForecastInput(
            date: forecast.date,
            tempMaxF: forecast.tempMaxF,
            tempMinF: forecast.tempMinF,
            windMaxMph: forecast.windMaxMph,
            precipInches: forecast.precipInches,
            cloudCoverPct: forecast.cloudCoverPct
        )
        return scoringService.score(
            day: day,
            aspect: crag.aspect,
            rockType: crag.rockType
        )
    }

    private func computeBreakdowns(for crag: Crag) {
        for forecast in crag.forecasts {
            scoreBreakdowns[forecast.date] = breakdown(for: forecast, crag: crag)
        }
    }
}
