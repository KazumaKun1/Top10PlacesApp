//
//  MapService.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import Foundation
import CoreLocation
import CoreData
import MapKit
import Combine

protocol MapServiceProtocol {
    func getPlaces(near coordinate: CLLocationCoordinate2D) -> AnyPublisher<[Place], Error>
}

class MapService: MapServiceProtocol {
    private let persistenceController = PersistenceController.shared
    private let searcher = MapKitPlaceSearcher()
    
    func getPlaces(near coordinate: CLLocationCoordinate2D) -> AnyPublisher<[Place], Error> {
        Deferred { [searcher] in
            Future {
                try await searcher.searchPlaces(near: coordinate)
            }
        }.eraseToAnyPublisher()
    }
    
    private func getPlacesObject(from items: [[String: Any]]) throws -> [Place]? {
        let places = try items.enumerated().map({ index, placeJSON in
            let jsonData = try JSONSerialization.data(withJSONObject: placeJSON)
            
            var place = try JSONDecoder().decode(Place.self, from: jsonData)
            
            let actualRank = index + 1
            
            place.rank = Rank(ordinal: actualRank.ordinalString(), rawValue: actualRank)
            place.position.coordinate = CLLocationCoordinate2D(latitude: place.position.lat, longitude: place.position.lng)
            
            return place
        })
        
        return places
    }
    
    private func saveRetrievedPlaces(from items: [[String: Any]], latitude: CLLocationDegrees, longtitude: CLLocationDegrees) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: items, options: [])

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            let context = persistenceController.container.viewContext
            
            let fetchRequest: NSFetchRequest<UserLocation> = UserLocation.fetchRequest()
            
            fetchRequest.predicate = NSPredicate(format: "latitude == %f AND longtitude == %f", argumentArray: [latitude, longtitude])
            fetchRequest.fetchLimit = 1
            
            let existingLocationRecords = try context.fetch(fetchRequest)
            
            //Checking if User Location is existing
            if let userLocation = existingLocationRecords.first {
                //Update places object from user location
                
                let places = userLocation.places
                places?.json = jsonString
                
                try context.save()
            } else {
                //Create a new User Location and Places Object
                let userLocation = UserLocation(context: context)
                
                userLocation.latitude = latitude
                userLocation.longtitude = longtitude
                
                let places = Places(context: context)
                
                places.json = jsonString
                
                places.userLocation = userLocation
                userLocation.places = places
                
                try context.save()
            }
        }
    }
    
    func retrievePlacesData(from latitude: CLLocationDegrees, and longtitude: CLLocationDegrees) -> [Place]? {
        let fetchRequest: NSFetchRequest<UserLocation> = UserLocation.fetchRequest()
        
        let predicate = NSPredicate(format: "latitude == %f AND longtitude == %f", argumentArray: [latitude, longtitude])
        
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            let context = persistenceController.container.viewContext
            
            let userLocations = try context.fetch(fetchRequest)
            
            guard let userLocation = userLocations.first,
                  let jsonData = userLocation.places?.json?.data(using: .utf8),
                  let placesData = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                  let places = try getPlacesObject(from: placesData) else {
                return nil
            }
            
            return places
        } catch { }
        
        return nil
    }
}
