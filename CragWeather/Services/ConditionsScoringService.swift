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
    let aspectBonus: Double
    let rockModifier: Double
    let total: Double
}

struct ConditionsScoringService {
    func score(
        day: DayForecastInput,
        aspect: Aspect?,
        rockType: RockType?
    ) -> ScoreBreakdown {
        let avgTemp = (day.tempMaxF + day.tempMinF) / 2
        let month = Calendar.current.component(.month, from: day.date)

        let tempScore = temperatureScore(avgTemp: avgTemp)
        let windScore = windScore(day.windMaxMph)
        let precipScore = precipitationScore(day.precipInches, rockType: rockType)
        let cloudScore = cloudCoverScore(day.cloudCoverPct, avgTemp: avgTemp)
        let aspectBonus = aspect.map { $0.sunExposureBonus(month: month) * 10 } ?? 0
        let rockModifier = rockType?.rainSensitivity ?? 1.0

        let weighted =
            tempScore * 0.40 +
            windScore * 0.25 +
            precipScore * 0.25 +
            cloudScore * 0.10

        let adjustedPrecipImpact = (1 - precipScore) * (rockModifier - 1) * 0.5
        let total = min(100, max(0, weighted + aspectBonus - adjustedPrecipImpact * 100))

        return ScoreBreakdown(
            temperature: tempScore,
            wind: windScore,
            precipitation: precipScore,
            cloudCover: cloudScore,
            aspectBonus: aspectBonus,
            rockModifier: rockModifier,
            total: total
        )
    }

    func makeForecast(
        cragId: String,
        day: DayForecastInput,
        aspect: Aspect?,
        rockType: RockType?
    ) -> CragForecast {
        let breakdown = score(
            day: day,
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

    private func temperatureScore(avgTemp: Double) -> Double {
        let ideal: Double = 65
        let lower = ideal - 5
        let upper = ideal + 5

        if avgTemp >= lower && avgTemp <= upper {
            return 100
        }
        if avgTemp < lower {
            let diff = lower - avgTemp
            return max(0, 100 - diff * 3)
        }
        let diff = avgTemp - upper
        return max(0, 100 - diff * 4)
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

    private func cloudCoverScore(_ pct: Double, avgTemp: Double) -> Double {
        let idealTemp: Double = 65
        let lower = idealTemp - 5
        let upper = idealTemp + 5
        
        if avgTemp > upper { return 100 - pct }
        if avgTemp < lower { return pct }
        return 100
    }
}
