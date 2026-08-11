//
//  RegionSummaryTests.swift
//  CragWeatherTests
//

import Foundation
import Testing
@testable import CragWeather

struct RegionSummaryTests {
    @Test func eligibleWhenCragCountPositive() {
        let region = CragFixtures.regionSummary(cragCount: 5, lastCragSyncDate: .now)
        #expect(region.isEligibleForPicker)
    }

    @Test func eligibleWhenNeverSynced() {
        let region = CragFixtures.regionSummary(cragCount: 0, lastCragSyncDate: nil)
        #expect(region.isEligibleForPicker)
    }

    @Test func hiddenWhenSyncedWithZeroCrags() {
        let region = CragFixtures.regionSummary(cragCount: 0, lastCragSyncDate: .now)
        #expect(!region.isEligibleForPicker)
    }
}
