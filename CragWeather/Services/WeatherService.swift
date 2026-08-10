//
//  WeatherService.swift
//  CragWeather
//

import Foundation

enum WeatherServiceError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Open-Meteo."
        case .apiError(let message):
            return "Open-Meteo error: \(message)"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

final class WeatherService {
    static let shared = WeatherService()

    static let forecastBase = URL(string: "https://api.open-meteo.com/v1/forecast")!
    static let elevationBase = URL(string: "https://api.open-meteo.com/v1/elevation")!
    static let batchSize = 25
    static let cacheTTL: TimeInterval = 2 * 60 * 60
    static let requestDelayNanoseconds: UInt64 = 300_000_000

    private var forecastCache: [String: (fetchedAt: Date, days: [DayForecastInput])] = [:]

    static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }

    func isCacheValid(for cragId: String) -> Bool {
        guard let entry = forecastCache[cragId] else { return false }
        return Date().timeIntervalSince(entry.fetchedAt) < Self.cacheTTL
    }

    func cachedForecast(for cragId: String) -> [DayForecastInput]? {
        guard isCacheValid(for: cragId) else { return nil }
        return forecastCache[cragId]?.days
    }

    func fetchElevations(for crags: [(id: String, lat: Double, lng: Double)]) async throws -> [String: Double] {
        var results: [String: Double] = [:]
        let chunks = stride(from: 0, to: crags.count, by: Self.batchSize).map {
            Array(crags[$0..<min($0 + Self.batchSize, crags.count)])
        }

        for chunk in chunks {
            let latitudes = chunk.map { String($0.lat) }.joined(separator: ",")
            let longitudes = chunk.map { String($0.lng) }.joined(separator: ",")
            var components = URLComponents(url: Self.elevationBase, resolvingAgainstBaseURL: false)!
            components.queryItems = [
                URLQueryItem(name: "latitude", value: latitudes),
                URLQueryItem(name: "longitude", value: longitudes)
            ]

            let data = try await fetchData(from: components.url!)
            let decoded = try JSONDecoder().decode(ElevationResponse.self, from: data)
            for (index, crag) in chunk.enumerated() where index < decoded.elevation.count {
                results[crag.id] = decoded.elevation[index]
            }

            try await Task.sleep(nanoseconds: Self.requestDelayNanoseconds)
        }

        return results
    }

    func fetchForecasts(forCentroids centroids: [CentroidLocation]) async throws -> [ForecastBatchResult] {
        var results: [ForecastBatchResult] = []
        let chunks = stride(from: 0, to: centroids.count, by: Self.batchSize).map {
            Array(centroids[$0..<min($0 + Self.batchSize, centroids.count)])
        }

        for chunk in chunks {
            let uncached = chunk.filter {
                !isCacheValid(for: $0.id) && Self.isValidCoordinate(latitude: $0.latitude, longitude: $0.longitude)
            }
            if uncached.isEmpty {
                for centroid in chunk {
                    if let days = cachedForecast(for: centroid.id) {
                        results.append(ForecastBatchResult(cragId: centroid.id, days: days))
                    }
                }
                continue
            }

            let latitudes = uncached.map { String($0.latitude) }.joined(separator: ",")
            let longitudes = uncached.map { String($0.longitude) }.joined(separator: ",")

            var components = URLComponents(url: Self.forecastBase, resolvingAgainstBaseURL: false)!
            components.queryItems = forecastQueryItems(
                latitudes: latitudes,
                longitudes: longitudes,
                elevations: uncached.map(\.elevationMeters)
            )

            let data = try await fetchData(from: components.url!)
            let decoded = try parseForecastBatch(data: data, cragCount: uncached.count)

            for (index, centroid) in uncached.enumerated() where index < decoded.count {
                let days = decoded[index]
                forecastCache[centroid.id] = (Date(), days)
                results.append(ForecastBatchResult(cragId: centroid.id, days: days))
            }

            for centroid in chunk where isCacheValid(for: centroid.id) {
                if let days = cachedForecast(for: centroid.id),
                   !results.contains(where: { $0.cragId == centroid.id }) {
                    results.append(ForecastBatchResult(cragId: centroid.id, days: days))
                }
            }

            try await Task.sleep(nanoseconds: Self.requestDelayNanoseconds)
        }

        return results
    }

    func fetchForecasts(for crags: [Crag]) async throws -> [ForecastBatchResult] {
        var results: [ForecastBatchResult] = []
        let chunks = stride(from: 0, to: crags.count, by: Self.batchSize).map {
            Array(crags[$0..<min($0 + Self.batchSize, crags.count)])
        }

        for chunk in chunks {
            let uncached = chunk.filter {
                !isCacheValid(for: $0.openBetaId)
                    && Self.isValidCoordinate(latitude: $0.latitude, longitude: $0.longitude)
            }
            if uncached.isEmpty {
                for crag in chunk {
                    if let days = cachedForecast(for: crag.openBetaId) {
                        results.append(ForecastBatchResult(cragId: crag.openBetaId, days: days))
                    }
                }
                continue
            }

            let latitudes = uncached.map { String($0.latitude) }.joined(separator: ",")
            let longitudes = uncached.map { String($0.longitude) }.joined(separator: ",")

            var components = URLComponents(url: Self.forecastBase, resolvingAgainstBaseURL: false)!
            components.queryItems = forecastQueryItems(
                latitudes: latitudes,
                longitudes: longitudes,
                elevations: uncached.map(\.elevationMeters)
            )

            let data = try await fetchData(from: components.url!)
            let decoded = try parseForecastBatch(data: data, cragCount: uncached.count)

            for (index, crag) in uncached.enumerated() where index < decoded.count {
                let days = decoded[index]
                forecastCache[crag.openBetaId] = (Date(), days)
                results.append(ForecastBatchResult(cragId: crag.openBetaId, days: days))
            }

            for crag in chunk where isCacheValid(for: crag.openBetaId) {
                if let days = cachedForecast(for: crag.openBetaId),
                   !results.contains(where: { $0.cragId == crag.openBetaId }) {
                    results.append(ForecastBatchResult(cragId: crag.openBetaId, days: days))
                }
            }

            try await Task.sleep(nanoseconds: Self.requestDelayNanoseconds)
        }

        return results
    }

    func fetchForecast(for crag: Crag) async throws -> [DayForecastInput] {
        if let cached = cachedForecast(for: crag.openBetaId) {
            return cached
        }

        guard Self.isValidCoordinate(latitude: crag.latitude, longitude: crag.longitude) else {
            throw WeatherServiceError.apiError("This crag is missing valid map coordinates.")
        }

        var components = URLComponents(url: Self.forecastBase, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "latitude", value: String(crag.latitude)),
            URLQueryItem(name: "longitude", value: String(crag.longitude)),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max,cloud_cover_mean"),
            URLQueryItem(name: "forecast_days", value: "5"),
            URLQueryItem(name: "timezone", value: "America/Denver"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch")
        ]
        if let elevation = crag.elevationMeters {
            queryItems.append(URLQueryItem(name: "elevation", value: String(format: "%.0f", elevation)))
        }
        components.queryItems = queryItems

        let data = try await fetchData(from: components.url!)
        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
        let days = decoded.daily.dayInputs()
        forecastCache[crag.openBetaId] = (Date(), days)
        return days
    }

    private func forecastQueryItems(
        latitudes: String,
        longitudes: String,
        elevations: [Double?]
    ) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "latitude", value: latitudes),
            URLQueryItem(name: "longitude", value: longitudes),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max,cloud_cover_mean"),
            URLQueryItem(name: "forecast_days", value: "5"),
            URLQueryItem(name: "timezone", value: "America/Denver"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch")
        ]

        if elevations.allSatisfy({ $0 != nil }) {
            let elevationValue = elevations
                .map { String(format: "%.0f", $0!) }
                .joined(separator: ",")
            items.append(URLQueryItem(name: "elevation", value: elevationValue))
        }

        return items
    }

    private func parseForecastBatch(data: Data, cragCount: Int) throws -> [[DayForecastInput]] {
        if cragCount == 1 {
            let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
            return [decoded.daily.dayInputs()]
        }

        struct BatchItem: Decodable {
            let daily: DailyForecast
        }

        if let batch = try? JSONDecoder().decode([BatchItem].self, from: data), !batch.isEmpty {
            return batch.map { $0.daily.dayInputs() }
        }

        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
        return [decoded.daily.dayInputs()]
    }

    private func fetchData(from url: URL) async throws -> Data {
        try await WeatherRequestSerializer.shared.fetch(from: url)
    }
}

private actor WeatherRequestSerializer {
    static let shared = WeatherRequestSerializer()

    func fetch(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw WeatherServiceError.invalidResponse
            }

            if !(200...299).contains(http.statusCode) {
                if let reason = Self.apiErrorReason(from: data) {
                    throw WeatherServiceError.apiError(reason)
                }
                throw WeatherServiceError.invalidResponse
            }

            try Self.validateAPIResponse(data)
            return data
        } catch let error as WeatherServiceError {
            throw error
        } catch {
            throw WeatherServiceError.networkError(error)
        }
    }

    private static func apiErrorReason(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            json["error"] as? Bool == true
        else {
            return nil
        }
        return json["reason"] as? String
    }

    private static func validateAPIResponse(_ data: Data) throws {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return }

        if let errorObject = json as? [String: Any],
           errorObject["error"] as? Bool == true {
            let reason = errorObject["reason"] as? String ?? "Unknown API error"
            throw WeatherServiceError.apiError(reason)
        }
    }
}
