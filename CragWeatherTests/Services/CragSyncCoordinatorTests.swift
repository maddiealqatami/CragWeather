//
//  CragSyncCoordinatorTests.swift
//  CragWeatherTests
//

import SwiftData
import Testing
@testable import CragWeather

@MainActor
struct CragSyncCoordinatorTests {
    @Test func syncRegionsOnlyPopulatesRegionsAndCompletes() async throws {
        let context = try TestModelContainer.inMemoryContext()
        let coordinator = CragSyncCoordinator()

        await coordinator.syncRegionsOnly(modelContext: context)

        #expect(coordinator.phase == .complete)

        let regions = try context.fetch(FetchDescriptor<RegionSummary>())
        let bundledCount = RegionCatalogLoader.loadEntries().count
        #expect(regions.count >= bundledCount)
        #expect(regions.contains { $0.name == "Boulder" })
        #expect(regions.filter(\.isEligibleForPicker).count >= bundledCount)
    }
}
