//
//  ConditionsScoringService.swift
//  CragWeather
//

import Foundation

struct ScoreBreakdown {
    let temperature: Double
    let wind: Double
    let precipitation: Double
    let cloudCover: Double
    let elevationAdjust: Double
    let aspectBonus: Double
    let rockModifier: Double
    let total: Double
}

struct ConditionsScoringService {
    func score(
        day: DayForecastInput,
        elevationMeters: Double?,
        aspect: Aspect?,
        rockType: RockType?
    ) -> ScoreBreakdown {
        let avgTemp = (day.tempMaxF + day.tempMinF) / 2
        let elevationFeet = (elevationMeters ?? 1500) * 3.28084
        let month = Calendar.current.component(.month, from: day.date)

        let tempScore = temperatureScore(avgTemp: avgTemp, elevationFeet: elevationFeet)
        let windScore = windScore(day.windMaxMph)
        let precipScore = precipitationScore(day.precipInches, rockType: rockType)
        let cloudScore = cloudCoverScore(day.cloudCoverPct)
        let elevationScore = elevationAdjustScore(elevationFeet: elevationFeet, avgTemp: avgTemp)
        let aspectBonus = aspect.map { $0.sunExposureBonus(month: month) * 10 } ?? 0
        let rockModifier = rockType?.rainSensitivity ?? 1.0

        let weighted =
            tempScore * 0.30 +
            windScore * 0.25 +
            precipScore * 0.25 +
            cloudScore * 0.10 +
            elevationScore * 0.10

        let adjustedPrecipImpact = (1 - precipScore) * (rockModifier - 1) * 0.5
        let total = min(100, max(0, weighted + aspectBonus - adjustedPrecipImpact * 100))

        return ScoreBreakdown(
            temperature: tempScore,
            wind: windScore,
            precipitation: precipScore,
            cloudCover: cloudScore,
            elevationAdjust: elevationScore,
            aspectBonus: aspectBonus,
            rockModifier: rockModifier,
            total: total
        )
    }

    func makeForecast(
        cragId: String,
        day: DayForecastInput,
        elevationMeters: Double?,
        aspect: Aspect?,
        rockType: RockType?
    ) -> CragForecast {
        let breakdown = score(
            day: day,
            elevationMeters: elevationMeters,
            aspect: aspect,
            rockType: rockType
        )
        return CragForecast(
            cragId: cragId,
            date: day.date,
            tempMaxF: day.tempMaxF,
            tempMinF: day.tempMinF,
            windMaxMph: day.windMaxMph,
            precipInches: day.precipInches,
            cloudCoverPct: day.cloudCoverPct,
            conditionsScore: breakdown.total
        )
    }

    private func temperatureScore(avgTemp: Double, elevationFeet: Double) -> Double {
        let baseIdeal: Double = 65
        let elevationShift = max(0, (elevationFeet - 5000) / 1000) * 3
        let ideal = baseIdeal - elevationShift
        let lower = ideal - 15
        let upper = ideal + 15

        if avgTemp >= lower && avgTemp <= upper {
            return 100
        }
        if avgTemp < lower {
            let diff = lower - avgTemp
            return max(0, 100 - diff * 4)
        }
        let diff = avgTemp - upper
        return max(0, 100 - diff * 3)
    }

    private func windScore(_ mph: Double) -> Double {
        if mph <= 10 { return 100 }
        if mph <= 15 { return 100 - (mph - 10) * 8 }
        if mph <= 20 { return 60 - (mph - 15) * 10 }
        return max(0, 10 - (mph - 20) * 2)
    }

    private func precipitationScore(_ inches: Double, rockType: RockType?) -> Double {
        if inches <= 0 { return 100 }
        if inches < 0.01 { return 85 }
        let sensitivity = rockType?.rainSensitivity ?? 1.0
        let penalty = min(100, inches * 400 * sensitivity)
        return max(0, 100 - penalty)
    }

    private func cloudCoverScore(_ pct: Double) -> Double {
        if pct <= 70 { return 100 }
        return max(60, 100 - (pct - 70))
    }

    private func elevationAdjustScore(elevationFeet: Double, avgTemp: Double) -> Double {
        if elevationFeet < 6000 { return 90 }
        if elevationFeet < 9000 {
            return avgTemp > 45 ? 100 : 70
        }
        return avgTemp > 35 ? 85 : 55
    }
}
