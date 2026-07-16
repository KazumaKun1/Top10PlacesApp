//
//  LocationManager.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import Foundation
import CoreLocation
import Combine

enum LocationStreamError: Error {
    case networkFailure
    case noLocationFound
    case denied
    case unknown(Error)
}

protocol LocationManagerProtocol {
    var locationPublisher: PassthroughSubject<CLLocation, Never> { get }
    var permissionDeniedPublisher: CurrentValueSubject<Bool, Never> { get }
    var errorPublisher: PassthroughSubject<LocationStreamError, Never> { get }
}

class LocationManager: NSObject, LocationManagerProtocol, ObservableObject {
    private let manager = CLLocationManager()
    
    let locationPublisher = PassthroughSubject<CLLocation, Never>()
    let permissionDeniedPublisher = CurrentValueSubject<Bool, Never>(false)
    let errorPublisher = PassthroughSubject<LocationStreamError, Never>()
    
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
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            permissionDeniedPublisher.send(true)
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            errorPublisher.send(.noLocationFound)
            return
        }
    
        locationPublisher.send(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied: errorPublisher.send(.denied)
            case .network: errorPublisher.send(.networkFailure)
            default: errorPublisher.send(.unknown(error))
            }
        }
    }
}
