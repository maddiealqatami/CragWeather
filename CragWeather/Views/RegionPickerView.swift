//
//  RegionPickerView.swift
//  CragWeather
//

import SwiftUI
import SwiftData

struct RegionPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RegionSummary.name) private var regions: [RegionSummary]

    @Bindable var viewModel: RegionPickerViewModel
    var isPresentedAsSheet: Bool = false
    let onSelectRegion: (String) -> Void

    private var sortedRegions: [RegionSummary] {
        viewModel.sortedRegions(regions)
    }

    private var displayedRegions: [RegionSummary] {
        viewModel.displayedRegions(regions)
    }

    var body: some View {
        NavigationStack {
            Group {
                if !sortedRegions.isEmpty {
                    regionList
                } else {
                    switch viewModel.syncCoordinator.phase {
                    case .failed(let message):
                        errorView(message: message)
                    default:
                        syncingView
                    }
                }
            }
            .navigationTitle("Choose a Region")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: isPresentedAsSheet ? .automatic : .navigationBarDrawer(displayMode: .always),
                prompt: "Search regions"
            )
            .accessibilityIdentifier("regionPicker")
        }
    }

    private var regionList: some View {
        List {
            if displayedRegions.isEmpty {
                ContentUnavailableView(
                    viewModel.searchText.isEmpty ? "No Regions" : "No Results",
                    systemImage: "map",
                    description: Text(
                        viewModel.searchText.isEmpty
                            ? "Colorado climbing regions will appear here after sync."
                            : "Try a different search term."
                    )
                )
            } else {
                Section {
                    ForEach(displayedRegions, id: \.name) { region in
                        Button {
                            onSelectRegion(region.name)
                        } label: {
                            RegionRowView(region: region)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("regionRow-\(region.name)")
                    }
                } header: {
                    Text("Ranked by today's conditions")
                } footer: {
                    if isRefreshingScores {
                        Text("Scores updating… · Weather data © Open-Meteo")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("Weather data © Open-Meteo")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .accessibilityIdentifier("regionList")
        .refreshable {
            await viewModel.syncCoordinator.syncRegionsOnly(modelContext: modelContext)
        }
        .loadingOverlay(isVisible: isRefreshingScores, message: "Updating scores…")
    }

    private var isRefreshingScores: Bool {
        switch viewModel.syncCoordinator.phase {
        case .refreshingScores, .syncingRegions:
            return true
        default:
            return false
        }
    }

    private var syncingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading Colorado regions…")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Sync Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                Task {
                    await viewModel.syncCoordinator.syncRegionsOnly(modelContext: modelContext)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
    }
}
