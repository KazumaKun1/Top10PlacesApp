//
//  RankingPlacesViewModelTests.swift
//  Top10PlacesTests
//
//  Created by Arviejhay on 7/16/23.
//

import XCTest
import CoreLocation

class RankingPlacesViewModelTests: XCTestCase {
    var viewModel: RankingPlacesViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = RankingPlacesViewModel()
        viewModel.location = CLLocation(latitude: 10, longitude: 10)
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func test_didAutheticationSuccess__ShowNeedsPermissionAlert_ReturnFalse() {
        viewModel.didAuthenticationSuccessful()
        
        XCTAssertFalse(viewModel.showNeedsPermissionAlert)
    }
    
    func test_didAutheticationFailure_RetrievalStatus_ReturnStatusUnknown() {
        viewModel.didAuthenticationFailure()
        
        XCTAssertEqual(viewModel.retrievalStatus, .unknown)
    }
    
    func test_setGroupedPlacesIfNeeded_ReturnHasGrouped() {
        viewModel.places = MockPlaces.getPlaces()
        
        viewModel.setGroupedPlacesIfNeeded()
        
        let groupedPlaces = viewModel.places.filter({ place in
            place.annotationType == .grouped
        })
        
        XCTAssertTrue(groupedPlaces.count == 1)
    }
    
    func test_didFailGettingLocation_ReturnUnknown() {
        viewModel.didFailGettingLocation()
        
        XCTAssertEqual(viewModel.retrievalStatus, .unknown)
    }
    
    func test_GoToPlaceAnnotation_ReturnEqualCoordinates() {
        let place = MockPlaces.getNormalPlace()
        
        viewModel.goToPlaceAnnotation(place: place)
        
        XCTAssertEqual(viewModel.region.center, place.position.coordinate)
    }
    
    func test_GoToCurrentLocation_ReturnEqualCoordinates() {
        viewModel.goToCurrentLocation()
        
        XCTAssertEqual(viewModel.region.center, CLLocationCoordinate2D(latitude: 10, longitude: 10))
    }
}

