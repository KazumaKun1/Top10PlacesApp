//
//  Place.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import Foundation
import MapKit

/**
 It is used for determining what annotation to display in the map. It's mostly used for handling places with same coordinates that needs to be shown as a single annotation
 
 ```
 let annotationType: LocationAnnotationType = .hidden
 ```
 */

enum LocationAnnotationType {
    case single
    case grouped
    case hidden
}

/**
 This is a model that is used for representing one single annotation to the map and it used as a part of the logic to transform the places data into array of places.
 
 ```
 let place = Place(id: "1", title: "Mall", distance: 33, position: Position(lat: 10, lng: 10, coordinate: CLLocation(latitude: 10, longitude: 10)), address: Address(label: "Mall philippines"), rank: Rank(ordinal: "1st", rawValue: 1), annotationType: .hidden)
 ```
 
 */

struct Place: Identifiable, Decodable, Equatable {
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String
    var title: String
    var distance: Int
    var position: Position
    var address: Address
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case distance
        case position
        case address
    }
    
    //Not decodable properties
    var rank = Rank(ordinal: "1st", rawValue: 1)
    var annotationType: LocationAnnotationType = .single
}
