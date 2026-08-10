//
//  RegionPickerView.swift
//  CragWeather
//

import SwiftUI
import SwiftData

struct RegionPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var regions: [RegionSummary]

    @Bindable var viewModel: RegionPickerViewModel
    let onSelectRegion: (String) -> Void

    private var sortedRegions: [RegionSummary] {
        viewModel.sortedRegions(regions)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.syncCoordinator.phase {
                case .failed(let message) where sortedRegions.isEmpty:
                    errorView(message: message)
                case .idle where sortedRegions.isEmpty:
                    syncingView
                default:
                    regionList
                }
            }
            .navigationTitle("Choose a Region")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var regionList: some View {
        List {
            if sortedRegions.isEmpty {
                ContentUnavailableView(
                    "No Regions",
                    systemImage: "map",
                    description: Text("Colorado climbing regions will appear here after sync.")
                )
            } else {
                Section {
                    ForEach(sortedRegions, id: \.name) { region in
                        Button {
                            onSelectRegion(region.name)
                        } label: {
                            RegionRowView(region: region)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Ranked by today's climbability")
                } footer: {
                    if isRefreshingScores {
                        Text("Scores updating… · Weather data © Open-Meteo")
                            .font(.caption2)
                    } else {
                        Text("Weather data © Open-Meteo")
                            .font(.caption2)
                    }
                }
            }
        }
        .overlay {
            if isRefreshingScores {
                ProgressView("Updating scores…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
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
        }
    }
}
