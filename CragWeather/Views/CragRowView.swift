//
//  CragRowView.swift
//  CragWeather
//

import SwiftUI

struct CragRowView: View {
    let crag: Crag
    var showRegionBadge: Bool = false
    var hideRegionSubtitle: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ScoreBadge(score: crag.cachedScore)

            VStack(alignment: .leading, spacing: 4) {
                Text(crag.name)
                    .font(.headline)
                    .lineLimit(1)

                if showRegionBadge {
                    Text(crag.region)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15), in: Capsule())
                        .foregroundStyle(.secondary)
                } else if !hideRegionSubtitle {
                    Text(crag.region)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    if let feet = crag.elevationFeet {
                        Text("\(feet) ft")
                    }
                    if !crag.climbTypes.isEmpty {
                        Text(crag.climbTypes.map(\.displayName).joined(separator: " · "))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            if crag.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppTheme.favorite)
            }
        }
        .padding(.vertical, 4)
    }
}
