//
//  Rank.swift
//  Top10Places
//
//  Created by Arviejhay on 7/15/23.
//

import Foundation

/**
 It is a model used to represent the rank of a place. Mostly based on the distance from user's current location.
 
 ```
    let rank = Rank(ordinal: "1st", rawValue: 1)
 ```
 
 */

struct Rank {
    var ordinal: String
    var rawValue: Int
}
