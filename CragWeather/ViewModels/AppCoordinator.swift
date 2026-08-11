//
//  AppCoordinator.swift
//  CragWeather
//

import Foundation

@MainActor
@Observable
final class AppCoordinator {
    private static let selectedRegionKey = "selectedRegion"

    /// Session-only selection; intentionally not restored from UserDefaults so every launch starts on the region picker.
    var selectedRegion: String = "" {
        didSet {
            guard !selectedRegion.isEmpty else { return }
            UserDefaults.standard.set(selectedRegion, forKey: Self.selectedRegionKey)
        }
    }

    var hasSelectedRegion: Bool {
        !selectedRegion.isEmpty
    }

    func selectRegion(_ name: String) {
        selectedRegion = name
    }

    func clearSelectedRegion() {
        selectedRegion = ""
    }

    func validateSelectedRegion(availableRegionNames: Set<String>) {
        guard hasSelectedRegion else { return }
        if !availableRegionNames.contains(selectedRegion) {
            clearSelectedRegion()
        }
    }
}
