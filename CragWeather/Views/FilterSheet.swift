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
                    Section {
                        Picker("Type", selection: $filters.climbType) {
                            Text("Any").tag(ClimbType?.none)
                            ForEach(options.climbTypes) { type in
                                Text(type.displayName).tag(Optional(type))
                            }
                        }
                    } header: {
                        Label("Climb Type", systemImage: "figure.climbing")
                    }
                }

                if !options.elevationBands.isEmpty {
                    Section {
                        Picker("Band", selection: $filters.elevationBand) {
                            Text("Any").tag(ElevationBand?.none)
                            ForEach(options.elevationBands) { band in
                                Text(band.rawValue).tag(Optional(band))
                            }
                        }
                    } header: {
                        Label("Elevation", systemImage: "arrow.up.arrow.down")
                    }
                }

                if !options.aspects.isEmpty || !options.rockTypes.isEmpty {
                    Section {
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
                    } header: {
                        Label("Enriched Data", systemImage: "mountain.2")
                    }
                }

                Section {
                    Toggle("Favorites Only", isOn: $filters.favoritesOnly)
                } header: {
                    Label("Favorites", systemImage: "star")
                }

                if filters.isActive {
                    Section {
                        Button("Clear All Filters") {
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
