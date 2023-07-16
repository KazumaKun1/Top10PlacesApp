//
//  Int+ordinalStringTests.swift
//  Top10PlacesTests
//
//  Created by Arviejhay on 7/16/23.
//

import XCTest

class Int_ordinalStringTests: XCTestCase {
    func test_convert1_returns1st() {
        let number = 1
        let ordinalString = number.ordinalString()
        
        XCTAssertEqual(ordinalString, "1st")
    }
}
