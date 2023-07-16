//
//  Int+ordinalString.swift
//  Top10Places
//
//  Created by Arviejhay on 7/13/23.
//

import Foundation

extension Int {
    
    /**
         An Extension for the Int data type to provide the ordinal string of a number.
         
         It uses the NumberFormatter Class from Foundation Framework to generate the ordinal string of a number.
     
         ```
            let number = 1
            let rank = number.ordinalString()
         ```
        
         - returns:
                    The ordinal string representation of the number.
                    If self is '5' then the result is '5th'
     */
    
    func ordinalString() -> String {
        let formatter = NumberFormatter()
        
        formatter.numberStyle = .ordinal
        
        return formatter.string(from: NSNumber(value: self)) ?? "N/A"
    }
}
