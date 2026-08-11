//
//  RegionScoringService.swift
//  CragWeather
//

import Foundation
import SwiftData

@MainActor
final class RegionScoringService {
    private var weatherService = WeatherService.shared
    private let scoringService = ConditionsScoringService()

    func scoreRegions(_ regions: [RegionSummary], modelContext: ModelContext) async throws {
        guard !regions.isEmpty else { return }

        let centroids = regions.map { region in
            CentroidLocation(
                id: region.name,
                latitude: region.centroidLatitude,
                longitude: region.centroidLongitude,
                elevationMeters: region.representativeElevationMeters
            )
        }

        let batches = try await weatherService.fetchForecasts(forCentroids: centroids)

        for batch in batches {
            guard let region = regions.first(where: { $0.name == batch.cragId }) else { continue }
            guard let today = todayForecast(from: batch.days) else { continue }

            let breakdown = scoringService.score(
                day: today,
                aspect: nil,
                rockType: nil
            )
            region.cachedScore = breakdown.total
            region.cachedScoreDate = .now
        }

        try modelContext.save()
    }

    private func todayForecast(from days: [DayForecastInput]) -> DayForecastInput? {
        let calendar = Crag.denverCalendar
        let today = Date()

        if let todayDay = days.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            return todayDay
        }
        return days.min(by: { $0.date < $1.date })
    }
}
