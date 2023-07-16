//
//  Address.swift
//  Top10Places
//
//  Created by Arviejhay on 7/13/23.
//

import Foundation

/**
 It is a model to represent the address of a place in a map
 
 
 ```
    let address = Address(label: "Mall philippines")
 ```
 
 */

struct Address: Decodable {
    let label: String
}
