//
//  FilterSheet.swift
//  CragWeather
//

import SwiftUI

struct FilterSheet: View {
    @Binding var filters: CragFilters
    let options: CragFilterOptions
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if !options.climbTypes.isEmpty {
                    Section("Climb Type") {
                        Picker("Type", selection: $filters.climbType) {
                            Text("Any").tag(ClimbType?.none)
                            ForEach(options.climbTypes) { type in
                                Text(type.displayName).tag(Optional(type))
                            }
                        }
                    }
                }

                if !options.elevationBands.isEmpty {
                    Section("Elevation") {
                        Picker("Band", selection: $filters.elevationBand) {
                            Text("Any").tag(ElevationBand?.none)
                            ForEach(options.elevationBands) { band in
                                Text(band.rawValue).tag(Optional(band))
                            }
                        }
                    }
                }

                if !options.aspects.isEmpty || !options.rockTypes.isEmpty {
                    Section("Enriched Data") {
                        if !options.aspects.isEmpty {
                            Picker("Aspect", selection: $filters.aspect) {
                                Text("Any").tag(Aspect?.none)
                                ForEach(options.aspects) { aspect in
                                    Text(aspect.displayName).tag(Optional(aspect))
                                }
                            }
                        }

                        if !options.rockTypes.isEmpty {
                            Picker("Rock Type", selection: $filters.rockType) {
                                Text("Any").tag(RockType?.none)
                                ForEach(options.rockTypes) { rock in
                                    Text(rock.displayName).tag(Optional(rock))
                                }
                            }
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
