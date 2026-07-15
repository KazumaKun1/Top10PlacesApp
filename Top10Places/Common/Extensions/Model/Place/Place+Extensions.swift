//
//  Place+Extensions.swift
//  Top10Places
//
//  Created by Arviejhay Alejandro on 7/14/26.
//

import MapKit

extension Place {
    init(mapItem: MKMapItem, origin: CLLocation, rank: Rank) {
        let coordinate = mapItem.location.coordinate
        let itemLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        self.id = mapItem.location.debugDescription + (mapItem.name ?? UUID().uuidString)
        self.title = mapItem.name ?? "Unknown Place"
        self.distance = Int(origin.distance(from: itemLocation))
        self.position = Position(lat: coordinate.latitude, lng: coordinate.longitude, coordinate: coordinate)
        self.address = Address(label: mapItem.address?.shortAddress ?? "Unknown Address")
        self.rank = rank
        self.annotationType = .single
    }
}
