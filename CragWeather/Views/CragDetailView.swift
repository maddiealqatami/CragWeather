//
//  CragDetailView.swift
//  CragWeather
//

import SwiftUI
import SwiftData

struct CragDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var crag: Crag

    @State private var viewModel = CragDetailViewModel()

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    ScoreBadge(score: crag.cachedScore)
                        .scaleEffect(1.5)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(crag.region)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let feet = crag.elevationFeet {
                            Label("\(feet) ft", systemImage: "arrow.up.arrow.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !crag.climbTypes.isEmpty {
                            Text(crag.climbTypes.map(\.displayName).joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                if let aspect = crag.aspect {
                    LabeledContent("Aspect", value: aspect.displayName)
                }
                if let rock = crag.rockType {
                    LabeledContent("Rock", value: rock.displayName)
                }
            }

            Section("5-Day Forecast") {
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading forecast…")
                            .foregroundStyle(.secondary)
                    }
                } else if crag.forecasts.isEmpty, let error = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Forecast Unavailable", systemImage: "cloud.slash")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await viewModel.loadForecast(for: crag, modelContext: modelContext)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                    }
                } else if crag.forecasts.isEmpty {
                    ContentUnavailableView(
                        "No Forecast",
                        systemImage: "cloud",
                        description: Text("Weather data isn't available for this crag yet.")
                    )
                } else {
                    ForEach(crag.forecasts.sorted(by: { $0.date < $1.date }), id: \.date) { forecast in
                        VStack(alignment: .leading, spacing: 8) {
                            ForecastDayRow(forecast: forecast)
                            if Calendar.current.isDateInToday(forecast.date) {
                                scoreBreakdownView(for: forecast)
                            }
                        }
                    }
                }
            }

            Section {
                if let url = crag.openBetaURL {
                    Link(destination: url) {
                        Label("View on OpenBeta", systemImage: "link")
                    }
                }
                Link(destination: URL(string: "https://open-meteo.com/")!) {
                    Label("Weather by Open-Meteo (CC BY 4.0)", systemImage: "cloud.sun")
                }
            }
        }
        .navigationTitle(crag.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    crag.isFavorite.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: crag.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(crag.isFavorite ? AppTheme.favorite : .primary)
                }
            }
        }
        .task {
            await viewModel.loadForecast(for: crag, modelContext: modelContext)
        }
    }

    @ViewBuilder
    private func scoreBreakdownView(for forecast: CragForecast) -> some View {
        let breakdown = viewModel.breakdown(for: forecast, crag: crag)
        VStack(alignment: .leading, spacing: 4) {
            Text("Today's Score Breakdown")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            breakdownRow("Temperature", value: breakdown.temperature)
            breakdownRow("Wind", value: breakdown.wind)
            breakdownRow("Precipitation", value: breakdown.precipitation)
            breakdownRow("Cloud Cover", value: breakdown.cloudCover)
            breakdownRow("Elevation", value: breakdown.elevationAdjust)
            if breakdown.aspectBonus > 0 {
                HStack {
                    Text("Aspect Bonus")
                    Spacer()
                    Text(String(format: "+%.0f", breakdown.aspectBonus))
                }
                .font(.caption)
            }
        }
        .padding(.top, 4)
    }

    private func breakdownRow(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(String(format: "%.0f", value))
                .monospacedDigit()
        }
        .font(.caption)
    }
}
