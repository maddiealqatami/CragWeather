//
//  IntCragCountTests.swift
//  CragWeatherTests
//

import Testing
@testable import CragWeather

struct IntCragCountTests {
    @Test func singularCragCount() {
        #expect(1.formattedCragCount == "1 crag")
    }

    @Test func pluralCragCount() {
        #expect(0.formattedCragCount == "0 crags")
        #expect(2.formattedCragCount == "2 crags")
        #expect(42.formattedCragCount == "42 crags")
    }
}
