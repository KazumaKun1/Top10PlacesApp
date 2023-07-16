//
//  LocationRetrievalStateTests.swift
//  Top10PlacesTests
//
//  Created by OPSolutions on 7/16/23.
//

import XCTest

class LocationRetrievalStateTests: XCTestCase {
    func test_GetIconFromSuccess_ReturnsSuccessResource() {
        let state: LocationRetrievalState = .success
        
        let resource = state.getIcon()
        
        XCTAssertTrue(resource.iconName == "checkmark.circle.fill" && resource.color == .green)
    }
    
    func test_GetIconFromPrecached_ReturnsPrecachedResource() {
        let state: LocationRetrievalState = .precached
        
        let resource = state.getIcon()
        
        XCTAssertTrue(resource.iconName == "arrow.down.to.line.circle.fill" && resource.color == .blue)
    }
    
    func test_GetIconFromOngoing_ReturnsBlankResource() {
        let state: LocationRetrievalState = .ongoing
        
        let resource = state.getIcon()
        
        XCTAssertTrue(resource.iconName == "" && resource.color == .clear)
    }
    
    func test_GetIconFromFailure_ReturnsFailureResource() {
        let state: LocationRetrievalState = .failure
        
        let resource = state.getIcon()
        
        XCTAssertTrue(resource.iconName == "xmark.circle.fill" && resource.color == .red)
    }
    func test_GetIconFromUnknown_ReturnsUnknownResource() {
        let state: LocationRetrievalState = .unknown
        
        let resource = state.getIcon()
        
        XCTAssertTrue(resource.iconName == "minus.circle.fill" && resource.color == .gray)
    }
}
