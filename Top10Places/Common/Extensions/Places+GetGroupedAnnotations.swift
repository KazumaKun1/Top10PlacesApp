//
//  Places+GetGroupedAnnotations.swift
//  Top10Places
//
//  Created by Arviejhay on 7/15/23.
//

extension Array where Element == Place {
    /**
    The purpose of the function is to handle the logic of showing one annotation on the map if there are places that have the same coordinates since each place is represented as one annotation and it will stack on each other on the map if it's unhandled.
     
     ```
         let places = [Place(), Place()] //Assumed that the place objects has coordinate information on position object
         let groupedPlaces = places.getGroupdAnnotations(for: places)
     ```
     
     - parameter Place: An non-optional place object that's selected on the map.
     - returns: Returns an optional array of places that have the same latitude and longtitude or coordinates. It will return a null value if the result of the filter returns an array of places if the number of elements is at most one object.
     - Warning: This function is only usable on array of places variable
     
     */
    
    func getGroupedAnnotations(for place: Place) -> [Place]? {
        let groupedPlaces = self.filter {
            $0.position.coordinate == place.position.coordinate
        }
        
        if groupedPlaces.count > 1 {
            return groupedPlaces
        }
        
        return nil
    }
}
