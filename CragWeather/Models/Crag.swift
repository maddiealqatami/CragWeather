//
//  Crag.swift
//  CragWeather
//

import Foundation
import SwiftData

@Model
final class Crag {
    @Attribute(.unique) var openBetaId: String
    var name: String
    var region: String
    var latitude: Double
    var longitude: Double
    var elevationMeters: Double?
    var climbTypesRaw: String
    var aspectRaw: String?
    var rockTypeRaw: String?
    var isFavorite: Bool
    var lastSyncedAt: Date
    var cachedScore: Double?
    var cachedScoreDate: Date?
    var forecasts: [CragForecast]

    init(
        openBetaId: String,
        name: String,
        region: String,
        latitude: Double,
        longitude: Double,
        elevationMeters: Double? = nil,
        climbTypes: [ClimbType] = [],
        aspect: Aspect? = nil,
        rockType: RockType? = nil,
        isFavorite: Bool = false,
        lastSyncedAt: Date = .now,
        cachedScore: Double? = nil,
        cachedScoreDate: Date? = nil,
        forecasts: [CragForecast] = []
    ) {
        self.openBetaId = openBetaId
        self.name = name
        self.region = region
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.climbTypesRaw = climbTypes.map(\.rawValue).sorted().joined(separator: ",")
        self.aspectRaw = aspect?.rawValue
        self.rockTypeRaw = rockType?.rawValue
        self.isFavorite = isFavorite
        self.lastSyncedAt = lastSyncedAt
        self.cachedScore = cachedScore
        self.cachedScoreDate = cachedScoreDate
        self.forecasts = forecasts
    }

    var climbTypes: [ClimbType] {
        get {
            climbTypesRaw
                .split(separator: ",")
                .compactMap { ClimbType(rawValue: String($0)) }
        }
        set {
            climbTypesRaw = newValue.map(\.rawValue).sorted().joined(separator: ",")
        }
    }

    var aspect: Aspect? {
        get { aspectRaw.flatMap { Aspect(rawValue: $0) } }
        set { aspectRaw = newValue?.rawValue }
    }

    var rockType: RockType? {
        get { rockTypeRaw.flatMap { RockType(rawValue: $0) } }
        set { rockTypeRaw = newValue?.rawValue }
    }

    var elevationFeet: Int? {
        elevationMeters.map { Int($0 * 3.28084) }
    }

    var openBetaURL: URL? {
        URL(string: "https://openbeta.io/crag/\(openBetaId)")
    }

    var displayScore: String {
        guard let cachedScore else { return "—" }
        return String(format: "%.0f", cachedScore)
    }

    var bestForecastScore: Double? {
        forecasts.map(\.conditionsScore).max()
    }
}
