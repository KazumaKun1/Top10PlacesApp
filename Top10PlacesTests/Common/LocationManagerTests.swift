//
//  LocationManagerTests.swift
//  Top10PlacesTests
//
//  Created by Arviejhay on 7/16/23.
//

import XCTest
import CoreLocation

class LocationManagerTests: XCTestCase {
    func test_didAutheticateSuccessful_ReturnTrue() {
        let locationManager = MockLocationManager()
        
        locationManager.didAuthenticationSuccessful()
        
        XCTAssertTrue(locationManager.didAuthenticateSuccessful)
    }
    
    func test_didAutheticateFailure_ReturnTrue() {
        let locationManager = MockLocationManager()
        
        locationManager.didAuthenticationFailure()
        
        XCTAssertTrue(locationManager.didAuthenticateFailure)
    }
    
    func test_didGetUpdatedLocation_ReturnTrue() {
        let locationManager = MockLocationManager()
        
        locationManager.didGetUpdatedLocation(location: CLLocation(latitude: 10, longitude: 10))
        
        XCTAssertTrue(locationManager.didGetUpdatedLocation)
    }
    
    func test_didFailGettingLocation_ReturnTrue() {
        let locationManager = MockLocationManager()
        
        locationManager.didFailGettingLocation()
        
        XCTAssertTrue(locationManager.didFailedToGetLocation)
    }
}
