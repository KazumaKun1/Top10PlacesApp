//
//  CLLocationCoordinate2D+EquatableHashable.swift
//  Top10Places
//
//  Created by Arviejhay on 7/14/23.
//

import CoreLocation

extension CLLocationCoordinate2D: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
