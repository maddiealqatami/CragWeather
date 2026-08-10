//
//  CragListView.swift
//  CragWeather
//

import SwiftUI
import SwiftData

struct CragListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Crag.name) private var allCrags: [Crag]

    @Bindable var viewModel: CragListViewModel
    var selectedRegion: String? = nil
    var favoritesOnly: Bool = false
    var showRegionBadge: Bool = false
    var onChangeRegion: (() -> Void)? = nil

    @State private var showFilters = false

    private var scopedCrags: [Crag] {
        if let selectedRegion {
            return allCrags.filter { !$0.isBoulderCrag && $0.region == selectedRegion }
        }
        return allCrags.filter { !$0.isBoulderCrag }
    }

    private var displayedCrags: [Crag] {
        viewModel.filteredAndSorted(scopedCrags)
    }

    var body: some View {
        Group {
            switch viewModel.syncCoordinator.phase {
            case .idle, .syncingCrags, .syncingElevations, .syncingWeather:
                if scopedCrags.isEmpty, selectedRegion != nil {
                    syncingView
                } else {
                    cragList
                }
            case .syncingRegions, .refreshingScores, .complete, .failed:
                cragList
            }
        }
        .navigationTitle(navigationTitle)
        .searchable(text: $viewModel.filters.searchText, prompt: "Search crags")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Sort", selection: $viewModel.sortOption) {
                        ForEach(CragSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }

            if selectedRegion != nil, let onChangeRegion {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Change Region", systemImage: "map") {
                        onChangeRegion()
                    }
                }
            }

            if !favoritesOnly {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Label("Filter", systemImage: viewModel.filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(filters: $viewModel.filters)
        }
        .onAppear {
            if favoritesOnly {
                viewModel.showFavoritesOnly = true
                Task {
                    await viewModel.refreshFavorites(modelContext: modelContext, crags: allCrags)
                }
            } else if let selectedRegion {
                Task {
                    await viewModel.refreshRegion(modelContext: modelContext, region: selectedRegion)
                }
            }
        }
        .onChange(of: selectedRegion) { _, newRegion in
            guard let newRegion, !favoritesOnly else { return }
            Task {
                await viewModel.refreshRegion(modelContext: modelContext, region: newRegion)
            }
        }
    }

    private var navigationTitle: String {
        if favoritesOnly {
            return "Favorites"
        }
        if let selectedRegion {
            return selectedRegion
        }
        return "Colorado Crags"
    }

    private var cragList: some View {
        List {
            if displayedCrags.isEmpty {
                ContentUnavailableView(
                    favoritesOnly ? "No Favorites" : "No Crags Found",
                    systemImage: favoritesOnly ? "star" : "mountain.2",
                    description: Text(favoritesOnly ? "Star crags from the main list to save them here." : "Try adjusting your search or filters.")
                )
            } else {
                Section {
                    ForEach(displayedCrags, id: \.openBetaId) { crag in
                        NavigationLink {
                            CragDetailView(crag: crag)
                        } label: {
                            CragRowView(crag: crag, showRegionBadge: showRegionBadge)
                        }
                    }
                } footer: {
                    Text("\(displayedCrags.count) crags · Weather data © Open-Meteo")
                        .font(.caption2)
                }
            }
        }
        .refreshable {
            if favoritesOnly {
                await viewModel.refreshFavorites(modelContext: modelContext, crags: allCrags)
            } else if let selectedRegion {
                await viewModel.refreshRegion(modelContext: modelContext, region: selectedRegion)
            }
        }
        .overlay {
            if viewModel.isRefreshing || viewModel.syncCoordinator.phase == .syncingWeather {
                ProgressView("Updating weather…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else if case .syncingCrags = viewModel.syncCoordinator.phase {
                ProgressView("Loading crags…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else if viewModel.syncCoordinator.phase == .syncingElevations {
                ProgressView("Looking up elevations…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var syncingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(syncMessage)
                .font(.headline)
            if viewModel.syncCoordinator.syncedCragCount > 0 {
                Text("\(viewModel.syncCoordinator.syncedCragCount) crags loaded")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var syncMessage: String {
        switch viewModel.syncCoordinator.phase {
        case .idle:
            return "Preparing to load crags…"
        case .syncingCrags(let current):
            return "Loading crags… \(current)"
        case .syncingElevations:
            return "Looking up elevations…"
        case .syncingWeather:
            return "Fetching weather forecasts…"
        case .syncingRegions, .refreshingScores:
            return "Scoring regions…"
        default:
            return "Loading…"
        }
    }
}
