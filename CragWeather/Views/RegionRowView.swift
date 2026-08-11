//
//  RegionRowView.swift
//  CragWeather
//

import SwiftUI

struct RegionRowView: View {
    let region: RegionSummary

    var body: some View {
        HStack(spacing: 12) {
            ScoreBadge(score: region.cachedScore)

            VStack(alignment: .leading, spacing: 4) {
                Text(region.name)
                    .font(.headline)
                    .lineLimit(2)

                Text(cragCountText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let elevation = region.representativeElevationMeters {
                    Text("\(Int(elevation * 3.28084)) ft avg elevation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private var cragCountText: String {
        if region.cragCount > 0 {
            return region.cragCount.formattedCragCount
        }
        return "Crags load on selection"
    }
}
