//
//  MockPlaces.swift
//  Top10PlacesTests
//
//  Created by Arviejhay on 7/16/23.
//

import Foundation
import CoreLocation

class MockPlaces {
    static func getNormalPlace() -> Place {
        var centralMallCoordinates = Position(lat: 10.2, lng: 131.20)
        
        centralMallCoordinates.coordinate = CLLocationCoordinate2D(latitude: centralMallCoordinates.lat, longitude: centralMallCoordinates.lng)
        
        return Place(id: "1", title: "Central mall", distance: 10, position: centralMallCoordinates, address: Address(label: "Central Mall, Philippines"))
    }
    
    static func getCandidatePlace() -> Place {
        var imealRestaurantCoordinates = Position(lat: 13.6, lng: -128.20)
        
        imealRestaurantCoordinates.coordinate = CLLocationCoordinate2D(latitude: imealRestaurantCoordinates.lat, longitude: imealRestaurantCoordinates.lng)
        
        return Place(id: "3", title: "Imeal Restaurant", distance: 30, position: imealRestaurantCoordinates, address: Address(label: "Imeal Restaurant, Makati, Philippines"))
    }
    
    static func getPlaces() -> [Place] {
        var centralMallCoordinates = Position(lat: 10.2, lng: 131.20)
        var monumentalBuildingCoordinates = Position(lat: 14.2, lng: 102.20)
        var imealRestaurantCoordinates = Position(lat: 13.6, lng: -128.20)
        var fashionMallCoordinates = Position(lat: 13.6, lng: -128.20)
        var bridgerMallCoordinates = Position(lat: 13.6, lng: -128.20)
        var makeMallCoordinates = Position(lat: 14.35, lng: 122.20)
        
        centralMallCoordinates.coordinate = CLLocationCoordinate2D(latitude: centralMallCoordinates.lat, longitude: centralMallCoordinates.lng)
        monumentalBuildingCoordinates.coordinate = CLLocationCoordinate2D(latitude: monumentalBuildingCoordinates.lat, longitude: monumentalBuildingCoordinates.lng)
        imealRestaurantCoordinates.coordinate = CLLocationCoordinate2D(latitude: imealRestaurantCoordinates.lat, longitude: imealRestaurantCoordinates.lng)
        fashionMallCoordinates.coordinate = CLLocationCoordinate2D(latitude: fashionMallCoordinates.lat, longitude: fashionMallCoordinates.lng)
        bridgerMallCoordinates.coordinate = CLLocationCoordinate2D(latitude: bridgerMallCoordinates.lat, longitude: bridgerMallCoordinates.lng)
        makeMallCoordinates.coordinate = CLLocationCoordinate2D(latitude: makeMallCoordinates.lat, longitude: makeMallCoordinates.lng)
        
        let places = [
            Place(id: "1", title: "Central mall", distance: 10, position: centralMallCoordinates, address: Address(label: "Central Mall, Philippines")),
            Place(id: "2", title: "Monumental Building", distance: 20, position: monumentalBuildingCoordinates, address: Address(label: "Monumental Building, Philippines")),
            Place(id: "3", title: "Imeal Restaurant", distance: 30, position: imealRestaurantCoordinates, address: Address(label: "Imeal Restaurant, Makati, Philippines")),
            Place(id: "4", title: "Fashion mall", distance: 30, position: fashionMallCoordinates, address: Address(label: "Fashion mall, Makati, Philippines")),
            Place(id: "5", title: "Bridger mall", distance: 30, position: bridgerMallCoordinates, address: Address(label: "Bridger mall, Makati, Philippines")),
            Place(id: "6", title: "Make mall", distance: 120, position: makeMallCoordinates, address: Address(label: "Make Mall, Philippines"))]
        
        return places
    }
}
