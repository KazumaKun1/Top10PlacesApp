//
//  LocationRetrievalState.swift
//  Top10Places
//
//  Created by Arviejhay on 7/14/23.
//

import SwiftUI

/**
 This represents the status of the retrieval of the location mostly based on the delegates from LocationManager and the retrieval of places in the MapService.
 
 ```
 let state: LocationRetrievalState = .unknown
 ```
 
 */

enum LocationRetrievalState: Equatable {
    case success
    case precached
    case ongoing
    case failure
    case unknown
    
    /**
     It will retrieve the resources needed for displaying the appropriate status to the user based on the value.
     
     ```
     let state: LocationRetrievalState = .unknown
     let stateInfo = state.getIcon()
     let iconName = state.iconName
     let color = state.color
     ```
     
     - returns: A tuple containing two variables which are the icon name to be use for showing the approariate status to the user and color as well.
     
     */
    
    func getIcon() -> (iconName: String, color: Color) {
        switch self {
            case .success:
                return (iconName: "checkmark.circle.fill", color: .green)
            case .precached:
                return (iconName: "arrow.down.to.line.circle.fill", color: .blue)
            case .ongoing:
                return (iconName: "", color: .clear)
            case .failure:
                return (iconName: "xmark.circle.fill", color: .red)
            case .unknown:
                return (iconName: "minus.circle.fill", color: .gray)
        }
    }
}
