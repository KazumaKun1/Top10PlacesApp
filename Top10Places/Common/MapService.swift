//
//  MapService.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import Foundation
import CoreLocation
import CoreData

/**
 This is a class for handling the retrieval of places from an API or Core data.
 This handles also the saving of places in the core data.
 
 ```
 let mapService = MapService()
 ```
 
 */

class MapService {
    private let apiKey = "V66HBdH2CHRfiGedTdB7cbnuxbpRyLgcQ3GRLXEDwkQ"
    
    private let persistenceController = PersistenceController.shared
    
    /**
     This will retrieve the places data from HERE browse API return the data as an array of places. If there are issues or errors within the retrieval of data from API or processing of data into array of places, it will return a null value.
     
     ```
        let location = CLLocationCoordinates2D(latitude: 14.03, longtitude: -123.002)
        let places = await mapService.getPlacesFrom(latitude: location.latitude, longtitude: location.longtitude)
     ```
     
     - parameters:
        - latitude: A CLLocationDegrees parameter that represents the latitude of a point in a map.
        - longtitude: A CLLocationDegrees parameter that represents the longtitude of a point in a map.
     - returns: An optional array of places retrieved from an API. It will return a null value if
     - warning: This function is asynchronous using async keyword. Any function that calls this functions need to include await and Task block if needed to make it synchronous.
     
     */
    
    func getPlacesFrom(latitude: CLLocationDegrees, longtitude: CLLocationDegrees) async -> [Place]? {
        guard let url = URL(string: "https://browse.search.hereapi.com/v1/browse?at=\(latitude),\(longtitude)&limit=10&apiKey=\(apiKey)") else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            //Error Checking
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return nil
            }
            
            //Serialization of JSON from result
            guard let jsonDictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = jsonDictionary["items"] as? [[String: Any]],
                  let places = try getPlacesObject(from: items) else {
                return nil
            }
            
            try saveRetrievedPlaces(from: items, latitude: latitude, longtitude: longtitude)
            
            return places
        } catch { } //Any error encountered while retrieving the data will show a general message to the user.
        
        return nil
    }
    
    /**
     This will get the models object from swift objects processed from serialization of json to be used for maps.
     
     ```
         do {
            let places = try getPlacesObject(from: items)
         } catch { }
     ```
     
     - parameter items: An array of dictionaries that were processed by the json serialization from places json via API.
     - returns: An optional array of places to be used for the maps as annotations. If will return a null value if it has issues with serialization or decoding.
     - warning: This function has a throw keyword. It must be enclose into a do catch if used.
     
     */
    
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
    
    /**
     This will do a saving of location and places data to the core data for pre-catching and persisting of location. If it doesn't any record that has the same langtitude and longtitude, it will create a record. Otherwise, it will update it.
     
     ```
        try saveRetrievedPlaces(from: items, latitude: latitude, longtitude: longtitude)
     ```
     
     - parameters:
        - items: An item that contains the places data retrieved from an API .
        - latitude: the user's latitude coordinates.
        - longtitude: the user's longtitude coordinates.
     - warning: This function has a throw keyword. It must be enclose into a do catch if used.
     
     */
    
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
    
    /**
     This will retrieve the places data from the core data and process it into a swift objects.
     
     ```
        let placesData = try retrievePlacesData(from: 14.333, and: 142.333)
     ```
     
     - parameters:
        - latitude: the user's latitude coordinates.
        - longtitude: the user's longtitude coordinates.
     - returns: An optional array of places to be used to display annotations in the map. It will return a null value if it didn't retrieve any places data or has an issue with serialization/decoder.
     
     */
    
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
