//
//  MockLocationManager.swift
//  Top10PlacesTests
//
//  Created by Arviejhay on 7/16/23.
//

import Foundation
import CoreLocation

class MockLocationManager: LocationManagerDelegate {
    var didAuthenticateSuccessful = false
    var didAuthenticateFailure = false
    var didGetUpdatedLocation = false
    var didFailedToGetLocation = false
    
    func didAuthenticationSuccessful() {
        didAuthenticateSuccessful = true
    }
    
    func didAuthenticationFailure() {
        didAuthenticateFailure = true
    }
    
    func didGetUpdatedLocation(location: CLLocation) {
        didGetUpdatedLocation = true
    }
    
    func didFailGettingLocation() {
        didFailedToGetLocation = true
    }
}


