//
//  CragWeatherApp.swift
//  CragWeather
//

import SwiftUI
import SwiftData

@main
struct CragWeatherApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Crag.self,
            CragForecast.self,
            RegionSummary.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
