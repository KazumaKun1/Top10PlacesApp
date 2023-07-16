//
//  Places+GetGroupedAnnotationsTests.swift
//  Top10PlacesTests
//
//  Created by Arviejhay on 7/16/23.
//

import XCTest

class Places_GroupedAnnotationsTests: XCTestCase {
    func test_GetPlacesWithSameCoordinates_FromCandidatePlace_ReturnsGroupedPlaces() {
        let candidatePlace = MockPlaces.getCandidatePlace()
        let places = MockPlaces.getPlaces()
        
        let groupedPlaces = places.getGroupedAnnotations(for: candidatePlace)
        
        let groupedPlace = groupedPlaces?.first
        
        XCTAssertEqual(groupedPlace?.position.coordinate, candidatePlace.position.coordinate)
    }
    
    func test_GetPlacesWithSameCoordinates_FromNormalPlace_ReturnsNull() {
        let candidatePlace = MockPlaces.getNormalPlace()
        let places = MockPlaces.getPlaces()
        
        let groupedPlaces = places.getGroupedAnnotations(for: candidatePlace)
        
        XCTAssertNil(groupedPlaces)
    }
}
