//
//  WeatherDTO.swift
//  CragWeather
//

import Foundation

struct ElevationResponse: Decodable {
    let elevation: [Double]
}

struct ForecastResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let daily: DailyForecast
}

struct DailyForecast: Decodable {
    let time: [String]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationSum: [Double]
    let windSpeed10mMax: [Double]
    let cloudCoverMean: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case windSpeed10mMax = "wind_speed_10m_max"
        case cloudCoverMean = "cloud_cover_mean"
    }

    func dayInputs(limit: Int = 5) -> [DayForecastInput] {
        var results: [DayForecastInput] = []
        let count = min(limit, time.count)
        for index in 0..<count {
            guard let date = Self.dateFormatter.date(from: time[index]) else { continue }
            results.append(
                DayForecastInput(
                    date: date,
                    tempMaxF: temperature2mMax[index],
                    tempMinF: temperature2mMin[index],
                    windMaxMph: windSpeed10mMax[index],
                    precipInches: precipitationSum[index],
                    cloudCoverPct: cloudCoverMean[index]
                )
            )
        }
        return results
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/Denver")
        return formatter
    }()
}

struct DayForecastInput {
    let date: Date
    let tempMaxF: Double
    let tempMinF: Double
    let windMaxMph: Double
    let precipInches: Double
    let cloudCoverPct: Double
}

struct ForecastBatchResult {
    let cragId: String
    let days: [DayForecastInput]
}

struct CentroidLocation {
    let id: String
    let latitude: Double
    let longitude: Double
    let elevationMeters: Double?
}
