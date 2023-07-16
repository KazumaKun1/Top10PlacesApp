//
//  RankingPlacesViewModel.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import Foundation
import MapKit
import SwiftUI

/**
 A view model that's used for the 'MainView'. It contains the functions and published data that's used for presenting places in the maps as well as the delegate from the 'LocationManager'
 
 */

class RankingPlacesViewModel: ObservableObject {
    @ObservedObject private var locationManager = LocationManager()
    
    private let mapService = MapService()
    
    //MARK: Bool Alert Variable
    @Published var showNeedsPermissionAlert = false
    
    //MARK: Map Variable
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)) //Default Location if the location isn't retrieved yet
    @Published var location: CLLocation?
    
    @Published var retrievalStatus: LocationRetrievalState = .ongoing
    
    //MARK: Published Places Variable
    @Published var places: [Place] = [Place]()
    
    init() {
        locationManager.delegate = self
    }
}

//MARK: Map Delegates
extension RankingPlacesViewModel: LocationManagerDelegate {
    func didAuthenticationSuccessful() {
        showNeedsPermissionAlert = false
    }
    
    func didAuthenticationFailure() {
        //Present the alert only if the app already been launched more than one to prevent conflict of displaying the permissions alert
        if isAppAlreadyLaunchedOnce() {
            showNeedsPermissionAlert = true
        }
        
        retrievalStatus = .unknown
    }
    
    /**
     This function is used to check if the app is already been launched. It's used for preventing the permission alert to be displayed for the first time when the device asked for location.
     
     ```
         if isAppAlreadyLaunchedOnce() {
             showNeedsPermissionAlert = true
         }
     ```
     
     - returns: A boolean variable to check if the app is already been launched.
     
     */
    
    func isAppAlreadyLaunchedOnce() -> Bool {
        if UserDefaults.standard.bool(forKey: "isAppAlreadyLaunchedOnce") {
            return true
        }
        
        UserDefaults.standard.set(true, forKey: "isAppAlreadyLaunchedOnce")
        
        return false
    }
    
    /**
     This is where the processing of places happens after retrieving the location from LocationManager. It will check first if the location is stored on the core data.
     If it does, it will retrieve the location object as well as the places object since location has a one to one relationship with the places.
     Otherwise, it will retrieve the places data from the API then store it in the core data.
     
     */
    
    func didGetUpdatedLocation(location: CLLocation) {
        Task {
            self.location = location
            
            if let preCachedPlaces = mapService.retrievePlacesData(from: location.coordinate.latitude, and: location.coordinate.longitude) {
                places = preCachedPlaces
                retrievalStatus = .precached
            } else {
                await retrievePlaces()
            }
            
            setGroupedPlacesIfNeeded()
            
            goToCurrentLocation()
        }
    }
    
    /**
     This is used for configuring the places array to set type of annotation to present in the map. if there are no places that have the same coordinates, it will set as '.single'. Otherwise, it will set the first element of the places that have the same coordinates as '.grouped' then the rest will be '.hidden' to avoid stacking of annotations in the map.
     
     ```
         Task {
             self.location = location
             
             await retrievePlaces()
             
             setGroupedPlacesIfNeeded()
             
             goToCurrentLocation()
         }
     ```
     
     - warning: This function should only be called if there are elements in the places
     
     */
    
    func setGroupedPlacesIfNeeded() {
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
        
        self.places = modifiedPlaces
    }
    
    /**
     It sets the places variable if the 'getPlacesFrom' function returns an array as well as the status of the retrieval to be used for displaying the approariate icon to the user. Otherwise, it will set as an empty array and changed it to '.failture'.
     
     ```
         Task {
             retrievalStatus = .ongoing
             
             await retrievePlaces()
         }
     ```
     
     - warning: This function is asynchronous and it's suggested that to encase it in a task block.
     
     */
    
    private func retrievePlaces() async {
        if let location = self.location,
            let places = await getPlacesFrom(location: location) {
            self.places = places
            retrievalStatus = .success
        } else {
            self.places = [Place]()
            retrievalStatus = .failure
        }
    }
    
    /**
     It returns an array of places asynchronously via an API based on the coordinates of the user.
     
     ```
         if let location = self.location,
             let places = await getPlacesFrom(location: location) {
             self.places = places
             retrievalStatus = .success
         } else {
             self.places = [Place]()
             retrievalStatus = .failure
         }
     ```
     
     - parameter location: test.
     - returns: An optional array of places
     - warning: This function is asynchronous and it's suggested that to encase it in a task block.
     
     */
    
    private func getPlacesFrom(location: CLLocation) async -> [Place]? {
        return await mapService.getPlacesFrom(latitude: location.coordinate.latitude, longtitude: location.coordinate.longitude)
    }
    
    func didFailGettingLocation() {
        retrievalStatus = .unknown
    }
}

//MARK: Other Map Function
extension RankingPlacesViewModel {
    /**
     This will change the region of the map to focus on a specific place in the map.
     
     ```
         MapPinWithTitle(place: place, action: {
             withAnimation {
                 viewModel.goToPlaceAnnotation(place: place.wrappedValue)
                 selectedPlace = place.wrappedValue
             }
         })
     ```
     
     - parameter place: A place object retrieved from a selected annotation from the map..
     - warning: Region variable is @Published which means that it will update the view.
     
     */
    func goToPlaceAnnotation(place: Place) {
        let center = place.position.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
        
        self.region = MKCoordinateRegion(center: center, span: span)
    }
    
    /**
     This will change the region of the map to focus on the user's current location
     
     ```
         Task {
             self.location = location
             
             await retrievePlaces()
             
             setGroupedPlacesIfNeeded()
             
             goToCurrentLocation()
         }
     ```
     
     - warning: Region variable is @Published which means that it will update the view.
     
     */
    func goToCurrentLocation() {
        if let location = self.location {
            let regionCoverageInfo = getProperZoomOnMapWith(location: location)
            
            self.region = MKCoordinateRegion(center: regionCoverageInfo.center, span: regionCoverageInfo.span)
        }
    }
    
    /**
     The purpose of this function is to properly show all of the places including the user's location in the map for the user able to see.
     
     ```
         if let location = self.location {
             let regionCoverageInfo = getProperZoomOnMapWith(location: location)
             
             self.region = MKCoordinateRegion(center: regionCoverageInfo.center, span: regionCoverageInfo.span)
         }
     ```
     
     - parameter location: The location from either a specific point of the map, the user's current location or a specific place.
     - returns: A tuple that returns the parameters needed to create an 'MKCoordinateRegion'. The center represents the coordinates where in the map will focus and the span represents the zoom level of the map if it's zoom in or out. For this case, it will return the proper values based on the places coordinates and the user's location.
     
     */
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
    
    /**
     This will retrieve the places data from the API again and set the retrieval status to '.ongoing' for properly displaying of icon. This is used for the refresh button in 'MainView'.
     This will also update the json attribute of places entity from core data.
     
     ```
         CircularButton(retrievalStatus: $viewModel.retrievalStatus, imageName: "arrow.clockwise") {
             withAnimation {
                 viewModel.refreshPlaces()
                 
                 if showPlaceListPopup {
                     showPlaceListPopup = false
                 }
             }
         }
         .padding(.bottom, 20)
     ```
     
     - warning: This function is asynchronous and it's suggested that to encase it in a task block.
     
     */
    func refreshPlaces() {
        Task {
            retrievalStatus = .ongoing
            
            await retrievePlaces()
            
            if retrievalStatus == .failure {
                if let location = self.location,
                    let preCachedPlaces = mapService.retrievePlacesData(from: location.coordinate.latitude, and: location.coordinate.longitude) {
                    places = preCachedPlaces
                    retrievalStatus = .precached
                    setGroupedPlacesIfNeeded()
                }
            } else {
                setGroupedPlacesIfNeeded()
            }
            
            goToCurrentLocation()
        }
    }
}
