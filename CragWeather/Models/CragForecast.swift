//
//  CragForecast.swift
//  CragWeather
//

import Foundation
import SwiftData

@Model
final class CragForecast {
    var cragId: String
    var date: Date
    var tempMaxF: Double
    var tempMinF: Double
    var windMaxMph: Double
    var precipInches: Double
    var cloudCoverPct: Double
    var conditionsScore: Double

    init(
        cragId: String,
        date: Date,
        tempMaxF: Double,
        tempMinF: Double,
        windMaxMph: Double,
        precipInches: Double,
        cloudCoverPct: Double,
        conditionsScore: Double
    ) {
        self.cragId = cragId
        self.date = date
        self.tempMaxF = tempMaxF
        self.tempMinF = tempMinF
        self.windMaxMph = windMaxMph
        self.precipInches = precipInches
        self.cloudCoverPct = cloudCoverPct
        self.conditionsScore = conditionsScore
    }

    var scoreColor: ScoreLevel {
        ScoreLevel.from(score: conditionsScore)
    }
}

enum ScoreLevel {
    case excellent
    case good
    case fair
    case poor

    static func from(score: Double) -> ScoreLevel {
        switch score {
        case 80...: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .poor
        }
    }
}
