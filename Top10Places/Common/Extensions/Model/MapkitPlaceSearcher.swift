//
//  MapkitPlaceSearcher.swift
//  Top10Places
//
//  Created by Arviejhay Alejandro on 7/15/26.
//

import MapKit

struct MapKitPlaceSearcher {
    func searchPlaces(near coordinate: CLLocationCoordinate2D) async throws -> [Place] {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        
        let response = try await MKLocalSearch(request: request).start()
        let sorted = response.mapItems.sorted {
            origin.distance(from: $0.location) < origin.distance(from: $1.location)
        }
        return sorted.prefix(10).enumerated().map { index, item in
            let actualRank = index + 1
            return Place(mapItem: item, origin: origin, rank: Rank(ordinal: actualRank.ordinalString(), rawValue: actualRank))
        }
    }
}
