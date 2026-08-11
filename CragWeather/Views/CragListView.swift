//
//  CragListView.swift
//  CragWeather
//

import SwiftUI
import SwiftData

struct CragListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var queriedCrags: [Crag]

    @Bindable var viewModel: CragListViewModel
    var selectedRegion: String?
    var favoritesOnly: Bool = false
    var showRegionBadge: Bool = false
    var onChangeRegion: (() -> Void)?
    var onBackToRegions: (() -> Void)?

    @State private var showFilters = false

    init(
        viewModel: CragListViewModel,
        selectedRegion: String? = nil,
        favoritesOnly: Bool = false,
        showRegionBadge: Bool = false,
        onChangeRegion: (() -> Void)? = nil,
        onBackToRegions: (() -> Void)? = nil
    ) {
        _viewModel = Bindable(wrappedValue: viewModel)
        self.selectedRegion = selectedRegion
        self.favoritesOnly = favoritesOnly
        self.showRegionBadge = showRegionBadge
        self.onChangeRegion = onChangeRegion
        self.onBackToRegions = onBackToRegions

        if favoritesOnly {
            _queriedCrags = Query(
                filter: #Predicate<Crag> { $0.isFavorite == true },
                sort: [SortDescriptor(\Crag.name)]
            )
        } else if let region = selectedRegion {
            _queriedCrags = Query(
                filter: #Predicate<Crag> { $0.region == region },
                sort: [SortDescriptor(\Crag.name)]
            )
        } else {
            _queriedCrags = Query(sort: [SortDescriptor(\Crag.name)])
        }
    }

    private var scopedCrags: [Crag] {
        queriedCrags.filter { !$0.isBoulderCrag }
    }

    private var filterOptions: CragFilterOptions {
        CragFilterOptions.from(crags: scopedCrags)
    }

    private var displayedCrags: [Crag] {
        viewModel.filteredAndSorted(scopedCrags, favoritesOnly: favoritesOnly)
    }

    private var searchPrompt: String {
        favoritesOnly ? "Search favorites" : "Search crags"
    }

    var body: some View {
        Group {
            if shouldShowFullScreenLoading {
                syncingView
            } else {
                cragList
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: favoritesOnly ? $viewModel.favoritesSearchText : $viewModel.filters.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: searchPrompt
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 16) {
                    if let onBackToRegions, selectedRegion != nil, !favoritesOnly {
                        Button {
                            onBackToRegions()
                        } label: {
                            Label("Regions", systemImage: "chevron.left")
                        }
                        .accessibilityIdentifier("backToRegions")
                    }

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
            FilterSheet(filters: $viewModel.filters, options: filterOptions)
        }
        .onAppear {
            viewModel.sanitizeFilters(for: filterOptions)
            if favoritesOnly {
                Task {
                    await viewModel.refreshFavorites(modelContext: modelContext, crags: scopedCrags)
                }
            } else if let selectedRegion {
                Task {
                    await viewModel.refreshRegion(modelContext: modelContext, region: selectedRegion)
                }
            }
        }
        .onChange(of: selectedRegion) { _, newRegion in
            guard let newRegion, !favoritesOnly else { return }
            viewModel.sanitizeFilters(for: filterOptions)
            Task {
                await viewModel.refreshRegion(modelContext: modelContext, region: newRegion)
            }
        }
        .onChange(of: scopedCrags.count) { _, _ in
            viewModel.sanitizeFilters(for: filterOptions)
        }
    }

    private var shouldShowFullScreenLoading: Bool {
        guard scopedCrags.isEmpty, selectedRegion != nil else { return false }
        switch viewModel.syncCoordinator.phase {
        case .idle, .syncingCrags, .syncingElevations, .syncingWeather:
            return true
        default:
            return false
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
                            CragRowView(
                                crag: crag,
                                showRegionBadge: showRegionBadge,
                                hideRegionSubtitle: selectedRegion != nil && !showRegionBadge
                            )
                        }
                    }
                } footer: {
                    Text("\(displayedCrags.count.formattedCragCount) · Weather data © Open-Meteo")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .refreshable {
            if favoritesOnly {
                await viewModel.refreshFavorites(modelContext: modelContext, crags: scopedCrags)
            } else if let selectedRegion {
                await viewModel.refreshRegion(modelContext: modelContext, region: selectedRegion)
            }
        }
        .loadingOverlay(isVisible: isShowingListOverlay, message: overlayMessage)
    }

    private var isShowingListOverlay: Bool {
        if viewModel.isRefreshing { return true }
        switch viewModel.syncCoordinator.phase {
        case .syncingWeather, .syncingElevations:
            return true
        case .syncingCrags:
            return true
        default:
            return false
        }
    }

    private var overlayMessage: String {
        if viewModel.isRefreshing || viewModel.syncCoordinator.phase == .syncingWeather {
            return "Updating weather…"
        }
        if viewModel.syncCoordinator.phase == .syncingElevations {
            return "Looking up elevations…"
        }
        if case .syncingCrags = viewModel.syncCoordinator.phase {
            return "Loading crags…"
        }
        return "Loading…"
    }

    private var syncingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(syncMessage)
                .font(.headline)
                .foregroundStyle(.secondary)
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
