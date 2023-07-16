//
//  CLLocationCoordinate2D+EquatableHashableTests.swift
//  Top10PlacesTests
//
//  Created by Arviejhay on 7/16/23.
//

import XCTest
import CoreLocation

class CLLocationCoordinate2D_EquatableHashableTests: XCTestCase {
    let firstCoordinates = CLLocationCoordinate2D(latitude: 10.4324, longitude: -141.203)
    let secondCoordinates = CLLocationCoordinate2D(latitude: 10.4324, longitude: -141.203)
    
    func test_compareTwoSameCoordinates_ReturnsEqual() {
        XCTAssertTrue(firstCoordinates == secondCoordinates)
    }
    
    func test_compareTwoSameCoodinatesHashValue_ReturnsEqual() {
        XCTAssertEqual(firstCoordinates.hashValue, secondCoordinates.hashValue)
    }
}
