//
//  TestModelContainer.swift
//  CragWeatherTests
//

import SwiftData
@testable import CragWeather

enum TestModelContainer {
    static func inMemory() throws -> ModelContainer {
        let schema = Schema([Crag.self, CragForecast.self, RegionSummary.self])
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
    }

    static func inMemoryContext() throws -> ModelContext {
        ModelContext(try inMemory())
    }
}
