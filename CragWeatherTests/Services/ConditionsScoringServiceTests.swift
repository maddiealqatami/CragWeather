//
//  ConditionsScoringServiceTests.swift
//  CragWeatherTests
//

import Foundation
import Testing
@testable import CragWeather

struct ConditionsScoringServiceTests {
    private let service = ConditionsScoringService()

    @Test func excellentWeatherScoresHigh() {
        let breakdown = service.score(
            day: CragFixtures.excellentDay(),
            aspect: .south,
            rockType: .granite
        )
        #expect(breakdown.total >= 85)
        #expect(breakdown.total <= 100)
    }

    @Test func poorWeatherScoresLow() {
        let breakdown = service.score(
            day: CragFixtures.poorDay(),
            aspect: .north,
            rockType: .sandstone
        )
        #expect(breakdown.total < 50)
    }

    @Test func scoreIsClampedToValidRange() {
        let extreme = DayForecastInput(
            date: .now,
            tempMaxF: -10,
            tempMinF: -20,
            windMaxMph: 60,
            precipInches: 1.0,
            cloudCoverPct: 100
        )
        let breakdown = service.score(
            day: extreme,
            aspect: nil,
            rockType: .sandstone
        )
        #expect(breakdown.total >= 0)
        #expect(breakdown.total <= 100)
    }

    @Test func southAspectAddsBonusInWinter() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver")!
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        let winterDate = calendar.date(from: components)!

        let day = DayForecastInput(
            date: winterDate,
            tempMaxF: 65,
            tempMinF: 55,
            windMaxMph: 8,
            precipInches: 0,
            cloudCoverPct: 30
        )

        let withSouth = service.score(day: day, aspect: .south, rockType: .granite)
        let withNorth = service.score(day: day, aspect: .north, rockType: .granite)
        #expect(withSouth.aspectBonus > withNorth.aspectBonus)
        #expect(withSouth.aspectBonus - withNorth.aspectBonus >= 5)
    }

    @Test func makeForecastPersistsScoreOnModel() {
        let forecast = service.makeForecast(
            cragId: "crag-1",
            day: CragFixtures.excellentDay(),
            aspect: .east,
            rockType: .granite
        )
        #expect(forecast.cragId == "crag-1")
        #expect(forecast.conditionsScore >= 0)
        #expect(forecast.conditionsScore <= 100)
        #expect(forecast.tempMaxF == 68)
    }
}
