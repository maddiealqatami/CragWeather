//
//  CragFixtures.swift
//  CragWeatherTests
//

import Foundation
@testable import CragWeather

enum CragFixtures {
    static func sportCrag(
        openBetaId: String = "test-sport-1",
        name: String = "Test Sport Crag",
        region: String = "Boulder",
        latitude: Double = 40.015,
        longitude: Double = -105.270,
        elevationMeters: Double? = 2000,
        climbTypes: [ClimbType] = [.sport],
        aspect: Aspect? = .south,
        rockType: RockType? = .granite,
        isFavorite: Bool = false,
        cachedScore: Double? = 75,
        cachedScoreDate: Date? = .now
    ) -> Crag {
        Crag(
            openBetaId: openBetaId,
            name: name,
            region: region,
            latitude: latitude,
            longitude: longitude,
            elevationMeters: elevationMeters,
            climbTypes: climbTypes,
            aspect: aspect,
            rockType: rockType,
            isFavorite: isFavorite,
            cachedScore: cachedScore,
            cachedScoreDate: cachedScoreDate
        )
    }

    static func boulderOnlyCrag(
        openBetaId: String = "test-boulder-1",
        name: String = "Flagstaff Boulders",
        region: String = "Boulder"
    ) -> Crag {
        Crag(
            openBetaId: openBetaId,
            name: name,
            region: region,
            latitude: 40.0,
            longitude: -105.3,
            climbTypes: [.boulder]
        )
    }

    static func regionSummary(
        name: String = "Boulder",
        cragCount: Int = 10,
        cachedScore: Double? = 80,
        lastCragSyncDate: Date? = nil
    ) -> RegionSummary {
        RegionSummary(
            name: name,
            centroidLatitude: 40.015,
            centroidLongitude: -105.270,
            representativeElevationMeters: 1655,
            cragCount: cragCount,
            cachedScore: cachedScore,
            lastCragSyncDate: lastCragSyncDate
        )
    }

    static func excellentDay(date: Date = .now) -> DayForecastInput {
        DayForecastInput(
            date: date,
            tempMaxF: 68,
            tempMinF: 62,
            windMaxMph: 5,
            precipInches: 0,
            cloudCoverPct: 20
        )
    }

    static func poorDay(date: Date = .now) -> DayForecastInput {
        DayForecastInput(
            date: date,
            tempMaxF: 35,
            tempMinF: 28,
            windMaxMph: 35,
            precipInches: 0.25,
            cloudCoverPct: 95
        )
    }
}
