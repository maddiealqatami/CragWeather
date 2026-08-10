//
//  FilterSheet.swift
//  CragWeather
//

import SwiftUI

struct FilterSheet: View {
    @Binding var filters: CragFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Climb Type") {
                    Picker("Type", selection: $filters.climbType) {
                        Text("Any").tag(ClimbType?.none)
                        ForEach(ClimbType.appFilterOptions) { type in
                            Text(type.displayName).tag(Optional(type))
                        }
                    }
                }

                Section("Elevation") {
                    Picker("Band", selection: $filters.elevationBand) {
                        Text("Any").tag(ElevationBand?.none)
                        ForEach(ElevationBand.allCases) { band in
                            Text(band.rawValue).tag(Optional(band))
                        }
                    }
                }

                Section("Enriched Data") {
                    Picker("Aspect", selection: $filters.aspect) {
                        Text("Any").tag(Aspect?.none)
                        ForEach(Aspect.allCases) { aspect in
                            Text(aspect.displayName).tag(Optional(aspect))
                        }
                    }

                    Picker("Rock Type", selection: $filters.rockType) {
                        Text("Any").tag(RockType?.none)
                        ForEach(RockType.allCases) { rock in
                            Text(rock.displayName).tag(Optional(rock))
                        }
                    }
                }

                Section {
                    Toggle("Favorites Only", isOn: $filters.favoritesOnly)
                }

                if filters.isActive {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            filters = CragFilters()
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
