//
//  AppCoordinator.swift
//  CragWeather
//

import Foundation

@MainActor
@Observable
final class AppCoordinator {
    private static let selectedRegionKey = "selectedRegion"

    var selectedRegion: String = UserDefaults.standard.string(forKey: selectedRegionKey) ?? "" {
        didSet {
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
