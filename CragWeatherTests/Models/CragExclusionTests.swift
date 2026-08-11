//
//  CragExclusionTests.swift
//  CragWeatherTests
//

import Testing
@testable import CragWeather

struct CragExclusionTests {
    @Test func boulderOnlyClimbTypesAreExcluded() {
        #expect(CragExclusion.shouldExclude(climbTypes: [.boulder]))
        #expect(!CragExclusion.shouldExclude(climbTypes: [.sport]))
        #expect(!CragExclusion.shouldExclude(climbTypes: [.sport, .boulder]))
    }

    @Test func boulderAreaPathTokensAreExcluded() {
        #expect(
            CragExclusion.shouldExclude(
                climbTypes: [.sport],
                pathTokens: ["USA", "Colorado", "Flagstaff Boulders"]
            )
        )
        #expect(
            CragExclusion.isBoulderArea(pathTokens: [], name: "Castlewood Canyon Bouldering")
        )
    }

    @Test func mixedSportAndTradIsKept() {
        #expect(!CragExclusion.shouldExclude(climbTypes: [.sport, .trad]))
    }

    @Test func emptyClimbTypesAreNotExcludedUnlessBoulderArea() {
        #expect(!CragExclusion.shouldExclude(climbTypes: []))
        #expect(
            CragExclusion.shouldExclude(
                climbTypes: [],
                pathTokens: ["Boulders"]
            )
        )
    }
}
