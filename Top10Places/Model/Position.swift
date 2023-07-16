//
//  Position.swift
//  Top10Places
//
//  Created by Arviejhay on 7/13/23.
//

import Foundation
import CoreLocation

/**
 it is a model for representing the coordinates of a place in a map
 
 ```
    let position = Position(lat: 10, lng: 10, coordinate: CLLocation(latitude: 10, longitude: 10))
 ```
 
 */

struct Position: Decodable {
    let lat: Double
    let lng: Double
    
    enum CodingKeys: String, CodingKey {
        case lat
        case lng
    }
    
    //Not decodable property
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
}
