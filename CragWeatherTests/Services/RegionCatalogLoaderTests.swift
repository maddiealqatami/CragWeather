//
//  RegionCatalogLoaderTests.swift
//  CragWeatherTests
//

import SwiftData
import Testing
@testable import CragWeather

struct RegionCatalogLoaderTests {
    @Test func loadEntriesMatchesBundledCatalog() throws {
        let entries = RegionCatalogLoader.loadEntries()
        #expect(!entries.isEmpty)
        #expect(entries.allSatisfy { !$0.name.isEmpty })
    }

    @Test func syncBundledMetadataSeedsEmptyContainer() throws {
        let context = try TestModelContainer.inMemoryContext()
        RegionCatalogLoader.syncBundledMetadata(modelContext: context)

        let regions = try context.fetch(FetchDescriptor<RegionSummary>())
        let expectedCount = RegionCatalogLoader.loadEntries().count
        #expect(regions.count == expectedCount)
        #expect(regions.contains { $0.name == "Boulder" })
    }

    @Test func syncBundledMetadataIsIdempotent() throws {
        let context = try TestModelContainer.inMemoryContext()
        RegionCatalogLoader.syncBundledMetadata(modelContext: context)
        RegionCatalogLoader.syncBundledMetadata(modelContext: context)

        let regions = try context.fetch(FetchDescriptor<RegionSummary>())
        #expect(regions.count == RegionCatalogLoader.loadEntries().count)
    }
}
