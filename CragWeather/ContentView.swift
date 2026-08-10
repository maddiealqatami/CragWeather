//
//  ContentView.swift
//  CragWeather
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appCoordinator = AppCoordinator()
    @State private var listViewModel = CragListViewModel()
    @State private var regionPickerViewModel: RegionPickerViewModel?

    var body: some View {
        Group {
            if appCoordinator.hasSelectedRegion {
                TabView {
                    NavigationStack {
                        CragListView(
                            viewModel: listViewModel,
                            selectedRegion: appCoordinator.selectedRegion,
                            onChangeRegion: { appCoordinator.clearSelectedRegion() }
                        )
                    }
                    .tabItem {
                        Label("Crags", systemImage: "mountain.2")
                    }

                    NavigationStack {
                        CragListView(
                            viewModel: listViewModel,
                            favoritesOnly: true,
                            showRegionBadge: true
                        )
                    }
                    .tabItem {
                        Label("Favorites", systemImage: "star")
                    }
                }
            } else if let regionPickerViewModel {
                RegionPickerView(
                    viewModel: regionPickerViewModel,
                    onSelectRegion: { appCoordinator.selectRegion($0) }
                )
            } else {
                ProgressView("Loading…")
            }
        }
        .task {
            if regionPickerViewModel == nil {
                regionPickerViewModel = RegionPickerViewModel(syncCoordinator: listViewModel.syncCoordinator)
            }
            await listViewModel.syncCoordinator.syncRegionsOnly(modelContext: modelContext)

            let regions = (try? modelContext.fetch(FetchDescriptor<RegionSummary>())) ?? []
            appCoordinator.validateSelectedRegion(availableRegionNames: Set(regions.map(\.name)))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Crag.self, CragForecast.self, RegionSummary.self], inMemory: true)
}
