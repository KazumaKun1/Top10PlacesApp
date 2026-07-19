//
//  RankingPlacesViewModel.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import Foundation
import MapKit
import SwiftUI
import Combine

@MainActor
class RankingPlacesViewModel: ObservableObject {
    @ObservedObject private var locationManager = LocationManager()
    
    private let mapService: MapServiceProtocol
    
    //MARK: Bool Alert Variable
    @Published var showNeedsPermissionAlert = false
    
    //MARK: Map Variable
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)) //Default Location if the location isn't retrieved yet
    @Published var location: CLLocation?
    
    @Published var retrievalStatus: LocationRetrievalState = .ongoing
    
    // - MARK: Published Places Variable
    @Published var places: [Place] = [Place]()
    
    var cancellables = Set<AnyCancellable>()
    
    init(mapService: MapServiceProtocol) {
        self.mapService = mapService
        
        locationManager.permissionDeniedPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$showNeedsPermissionAlert)
        
        locationManager.locationPublisher
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] location in
                guard let self else { return }
                self.location = location
                self.retrievalStatus = .ongoing
            })
            .map { [mapService] location in
                mapService.getPlaces(near: location.coordinate)
                    .map { (LocationRetrievalState.success, $0) }
                    .catch { _ in Just((LocationRetrievalState.failure, [])) }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status, places in
                guard let self else { return }
                
                self.retrievalStatus = status
                
                self.places = getGroupAnnotation(places: places)
                
                self.goToCurrentLocation()
            }
            .store(in: &cancellables)
        
        locationManager.errorPublisher
            .sink { [weak self] locationError in
                guard let self else { return }
                switch locationError {
                case .networkFailure, .denied:
                    self.retrievalStatus = .failure
                case .unknown, .noLocationFound:
                    self.retrievalStatus = .unknown
                }
            }
            .store(in: &cancellables)
    }
}

//MARK: Other Map Function
extension RankingPlacesViewModel {
    func getGroupAnnotation(places: [Place]) -> [Place] {
        var modifiedPlaces = [Place]()
        
        for place in places {
            modifiedPlaces.append(place)
            
            if places.getGroupedAnnotations(for: place) != nil {
                var info = place
                
                if modifiedPlaces.getGroupedAnnotations(for: place) != nil {
                    info.annotationType = .hidden
                } else {
                    info.annotationType = .grouped
                }
                
                modifiedPlaces.removeLast()
                modifiedPlaces.append(info)
            }
        }
        
        return modifiedPlaces
    }
    
    func goToPlaceAnnotation(place: Place) {
        let center = place.position.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
        
        self.region = MKCoordinateRegion(center: center, span: span)
    }
    
    func goToCurrentLocation() {
        if let location = self.location {
            let regionCoverageInfo = getProperZoomOnMapWith(location: location)
            
            self.region = MKCoordinateRegion(center: regionCoverageInfo.center, span: regionCoverageInfo.span)
        }
    }
    
    private func getProperZoomOnMapWith(location: CLLocation) -> (center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        var span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        var center = location.coordinate
        
        if let firstPlace = self.places.first {
            var minLatitude = firstPlace.position.coordinate.latitude
            var maxLatitude = firstPlace.position.coordinate.latitude
            var minLongitude = firstPlace.position.coordinate.longitude
            var maxLongitude = firstPlace.position.coordinate.longitude
            
            for place in self.places {
                let latitude = place.position.coordinate.latitude
                let longitude = place.position.coordinate.longitude
                
                minLatitude = min(minLatitude, latitude)
                maxLatitude = max(maxLatitude, latitude)
                minLongitude = min(minLongitude, longitude)
                maxLongitude = max(maxLongitude, longitude)
            }
            
            minLatitude = min(minLatitude, location.coordinate.latitude)
            maxLatitude = max(maxLatitude, location.coordinate.latitude)
            minLongitude = min(minLongitude, location.coordinate.longitude)
            maxLongitude = max(maxLongitude, location.coordinate.longitude)
            
            center = CLLocationCoordinate2D(latitude: (minLatitude + maxLatitude) / 2, longitude: (minLongitude + maxLongitude) / 2) //Get the midpoint between the average latitude and average longtitude based on the available places and user location.
            span = MKCoordinateSpan(latitudeDelta: (maxLatitude - minLatitude) * 1.5, longitudeDelta: (maxLongitude - minLongitude) * 1.5) //Get the visible map size based on the available places and user location with 1.5 padding to have extra space on the map.
        }
        
        return (center: center, span: span)
    }
}
