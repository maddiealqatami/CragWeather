//
//  AppCoordinatorTests.swift
//  CragWeatherTests
//

import Testing
@testable import CragWeather

@MainActor
struct AppCoordinatorTests {
    @Test func startsWithNoSelectedRegion() {
        let coordinator = AppCoordinator()
        #expect(!coordinator.hasSelectedRegion)
        #expect(coordinator.selectedRegion.isEmpty)
    }

    @Test func selectRegionUpdatesState() {
        let coordinator = AppCoordinator()
        coordinator.selectRegion("Boulder")
        #expect(coordinator.hasSelectedRegion)
        #expect(coordinator.selectedRegion == "Boulder")
    }

    @Test func clearSelectedRegionResetsState() {
        let coordinator = AppCoordinator()
        coordinator.selectRegion("Boulder")
        coordinator.clearSelectedRegion()
        #expect(!coordinator.hasSelectedRegion)
    }

    @Test func validateSelectedRegionClearsInvalidSelection() {
        let coordinator = AppCoordinator()
        coordinator.selectRegion("Unknown Region")
        coordinator.validateSelectedRegion(availableRegionNames: ["Boulder", "Estes Park"])
        #expect(!coordinator.hasSelectedRegion)
    }

    @Test func validateSelectedRegionKeepsValidSelection() {
        let coordinator = AppCoordinator()
        coordinator.selectRegion("Boulder")
        coordinator.validateSelectedRegion(availableRegionNames: ["Boulder", "Estes Park"])
        #expect(coordinator.selectedRegion == "Boulder")
    }
}
