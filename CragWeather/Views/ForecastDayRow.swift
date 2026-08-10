//
//  ForecastDayRow.swift
//  CragWeather
//

import SwiftUI

struct ForecastDayRow: View {
    let forecast: CragForecast

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(forecast.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.subheadline.weight(.semibold))
                Text("\(Int(forecast.tempMinF))–\(Int(forecast.tempMaxF))°F")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 8) {
                    Label("\(Int(forecast.windMaxMph))", systemImage: "wind")
                    Label(String(format: "%.2f\"", forecast.precipInches), systemImage: "cloud.rain")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    ScoreLevelLabel(score: forecast.conditionsScore)
                    Text(String(format: "%.0f", forecast.conditionsScore))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
