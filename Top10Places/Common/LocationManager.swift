//
//  LocationManager.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import Foundation
import CoreLocation

/**
 
 ```
 class MyClass: LocationManagerDelegate {
     func didAuthenticationSuccessful() {
        //Additional code here
     }
     
     func didAuthenticationFailure() {
        //Additional code here
     }
     
     func didGetUpdatedLocation(location: CLLocation) {
        //Additional code here
     }
     
     func didFailGettingLocation() {
        //Additional code here
     }
 }
 ```
 
 */

protocol LocationManagerDelegate {
    func didAuthenticationSuccessful()
    func didAuthenticationFailure()
    func didGetUpdatedLocation(location: CLLocation)
    func didFailGettingLocation()
}

/**
 This is a  class that contains a CLLocationManager instance to handle additional logic for the CLLocationManagerDelegate and separate the responsibility of retrieving the location.
 
 ```
 let manager = LocationManager()
 ```
 
 */

class LocationManager: NSObject, ObservableObject {
    var delegate: LocationManagerDelegate?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.delegate = self
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .notDetermined, .restricted, .denied:
                manager.requestWhenInUseAuthorization()
                delegate?.didAuthenticationFailure()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
                delegate?.didAuthenticationSuccessful()
            default:
                break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
    
        self.delegate?.didGetUpdatedLocation(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.delegate?.didFailGettingLocation()
    }
}
