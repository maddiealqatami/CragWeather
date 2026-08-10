//
//  ContentView.swift
//  CragWeather
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var listViewModel = CragListViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                CragListView(viewModel: listViewModel)
            }
            .tabItem {
                Label("Crags", systemImage: "mountain.2")
            }

            NavigationStack {
                CragListView(viewModel: listViewModel, favoritesOnly: true)
            }
            .tabItem {
                Label("Favorites", systemImage: "star")
            }
        }
        .task {
            await listViewModel.syncCoordinator.syncIfNeeded(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Crag.self, CragForecast.self], inMemory: true)
}
