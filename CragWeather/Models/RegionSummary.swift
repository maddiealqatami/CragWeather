//
//  RegionSummary.swift
//  CragWeather
//

import Foundation
import SwiftData

@Model
final class RegionSummary {
    @Attribute(.unique) var name: String
    var centroidLatitude: Double
    var centroidLongitude: Double
    var representativeElevationMeters: Double?
    var cragCount: Int
    var cachedScore: Double?
    var cachedScoreDate: Date?
    var lastMetadataSyncDate: Date?

    static let scoreCacheTTL: TimeInterval = 4 * 60 * 60
    static let metadataCacheTTL: TimeInterval = 7 * 24 * 60 * 60

    var needsScoreRefresh: Bool {
        guard let cachedScore, let cachedScoreDate else { return true }
        return Date().timeIntervalSince(cachedScoreDate) >= Self.scoreCacheTTL
    }

    var needsMetadataRefresh: Bool {
        guard let lastMetadataSyncDate else { return true }
        return Date().timeIntervalSince(lastMetadataSyncDate) >= Self.metadataCacheTTL
    }

    init(
        name: String,
        centroidLatitude: Double,
        centroidLongitude: Double,
        representativeElevationMeters: Double? = nil,
        cragCount: Int = 0,
        cachedScore: Double? = nil,
        cachedScoreDate: Date? = nil,
        lastMetadataSyncDate: Date? = nil
    ) {
        self.name = name
        self.centroidLatitude = centroidLatitude
        self.centroidLongitude = centroidLongitude
        self.representativeElevationMeters = representativeElevationMeters
        self.cragCount = cragCount
        self.cachedScore = cachedScore
        self.cachedScoreDate = cachedScoreDate
        self.lastMetadataSyncDate = lastMetadataSyncDate
    }
}
