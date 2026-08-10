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

    private var weatherService = WeatherService()
    private let scoringService = ConditionsScoringService()

    func loadForecast(for crag: Crag, modelContext: ModelContext) async {
        if !crag.forecasts.isEmpty {
            computeBreakdowns(for: crag)
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let days = try await weatherService.fetchForecast(for: crag)

            for existing in crag.forecasts {
                modelContext.delete(existing)
            }
            crag.forecasts.removeAll()

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
            }

            if let today = crag.forecasts.first(where: { Calendar.current.isDateInToday($0.date) }) {
                crag.cachedScore = today.conditionsScore
            } else if let first = crag.forecasts.first {
                crag.cachedScore = first.conditionsScore
            }
            crag.cachedScoreDate = .now
            try modelContext.save()
            computeBreakdowns(for: crag)
        } catch {
            errorMessage = error.localizedDescription
        }
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
            elevationMeters: crag.elevationMeters,
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
