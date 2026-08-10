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
    var favoritesOnly: Bool = false

    @State private var showFilters = false

    private var displayedCrags: [Crag] {
        viewModel.filteredAndSorted(allCrags)
    }

    var body: some View {
        Group {
            switch viewModel.syncCoordinator.phase {
            case .idle, .syncingCrags, .syncingElevations, .syncingWeather:
                if allCrags.isEmpty {
                    syncingView
                } else {
                    cragList
                }
            case .complete:
                cragList
            case .failed(let message):
                errorView(message: message)
            }
        }
        .navigationTitle(favoritesOnly ? "Favorites" : "Colorado Crags")
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
            FilterSheet(
                filters: $viewModel.filters,
                regions: viewModel.regions(from: allCrags)
            )
        }
        .onAppear {
            if favoritesOnly {
                viewModel.showFavoritesOnly = true
            }
        }
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
                            CragRowView(crag: crag)
                        }
                    }
                } footer: {
                    Text("\(displayedCrags.count) crags · Weather data © Open-Meteo")
                        .font(.caption2)
                }
            }
        }
        .refreshable {
            await viewModel.refresh(modelContext: modelContext, crags: allCrags)
        }
        .overlay {
            if viewModel.isRefreshing || viewModel.syncCoordinator.phase == .syncingWeather {
                ProgressView("Updating weather…")
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
            return "Loading Colorado crags… \(current)"
        case .syncingElevations:
            return "Looking up elevations…"
        case .syncingWeather:
            return "Fetching weather forecasts…"
        default:
            return "Loading…"
        }
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Sync Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                Task {
                    await viewModel.syncCoordinator.performFullSync(modelContext: modelContext)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
