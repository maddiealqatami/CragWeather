//
//  CragWeatherUITests.swift
//  CragWeatherUITests
//

import XCTest

final class CragWeatherUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsRegionPicker() throws {
        let app = XCUIApplication()
        app.launch()

        let navBar = app.navigationBars["Choose a Region"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 30))
    }

    @MainActor
    func testSelectRegionNavigatesToCragList() throws {
        let app = XCUIApplication()
        app.launch()

        let firstRegion = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'regionRow-'")
        ).firstMatch
        XCTAssertTrue(firstRegion.waitForExistence(timeout: 45))
        firstRegion.tap()

        let cragsTab = app.tabBars.buttons["Crags"]
        XCTAssertTrue(cragsTab.waitForExistence(timeout: 15))
    }

    @MainActor
    func testSearchFiltersRegions() throws {
        let app = XCUIApplication()
        app.launch()

        let firstRegion = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'regionRow-'")
        ).firstMatch
        XCTAssertTrue(firstRegion.waitForExistence(timeout: 45))

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("Boulder")

        let boulderRow = app.buttons["regionRow-Boulder"]
        XCTAssertTrue(boulderRow.waitForExistence(timeout: 10))
    }
}
