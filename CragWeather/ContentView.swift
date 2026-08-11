//
//  ContentView.swift
//  CragWeather
//

import SwiftUI
import SwiftData

private enum MainTab: Hashable {
    case crags
    case favorites
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appCoordinator = AppCoordinator()
    @State private var listViewModel = CragListViewModel()
    @State private var regionPickerViewModel: RegionPickerViewModel
    @State private var selectedTab: MainTab = .crags
    @State private var showRegionPickerSheet = false

    init() {
        let listViewModel = CragListViewModel()
        _listViewModel = State(wrappedValue: listViewModel)
        _regionPickerViewModel = State(
            wrappedValue: RegionPickerViewModel(syncCoordinator: listViewModel.syncCoordinator)
        )
    }

    var body: some View {
        Group {
            if appCoordinator.hasSelectedRegion {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        CragListView(
                            viewModel: listViewModel,
                            selectedRegion: appCoordinator.selectedRegion,
                            onChangeRegion: { showRegionPickerSheet = true }
                        )
                    }
                    .tabItem {
                        Label("Crags", systemImage: "mountain.2")
                    }
                    .tag(MainTab.crags)

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
                    .tag(MainTab.favorites)
                }
                .sheet(isPresented: $showRegionPickerSheet) {
                    RegionPickerView(
                        viewModel: regionPickerViewModel,
                        isPresentedAsSheet: true,
                        onSelectRegion: { region in
                            appCoordinator.selectRegion(region)
                            showRegionPickerSheet = false
                        }
                    )
                }
            } else {
                RegionPickerView(
                    viewModel: regionPickerViewModel,
                    onSelectRegion: { appCoordinator.selectRegion($0) }
                )
            }
        }
        .onChange(of: selectedTab) { oldTab, _ in
            listViewModel.resetSearch(forFavoritesTab: oldTab == .favorites)
        }
        .task {
            await listViewModel.syncCoordinator.syncRegionsOnly(modelContext: modelContext)

            let regions = (try? modelContext.fetch(FetchDescriptor<RegionSummary>())) ?? []
            let eligibleNames = Set(regions.filter(\.isEligibleForPicker).map(\.name))
            appCoordinator.validateSelectedRegion(availableRegionNames: eligibleNames)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Crag.self, CragForecast.self, RegionSummary.self], inMemory: true)
}
