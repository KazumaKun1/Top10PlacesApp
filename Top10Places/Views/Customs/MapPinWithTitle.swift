//
//  MapPinWithTitle.swift
//  Top10Places
//
//  Created by Arviejhay on 7/13/23.
//

import SwiftUI
import MapKit

/**
 This is a view that represents an annotation in the map.
 
 ```
     MapPinWithTitle(place: place, action: {
         withAnimation {
             viewModel.goToPlaceAnnotation(place: place.wrappedValue)
             selectedPlace = place.wrappedValue
         }
     })
 ```
 
 - parameters:
    - place: A binding place object that has information about a certain place in the map.
    - action: It represents an action when the whole view is tapped. In this case, it represents an action to do when the annotation has been tapped.
 
 */

struct MapPinWithTitle: View {
    @Binding var place: Place
    
    var action: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                Image(systemName: "circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .shadow(radius: 3, x: 0, y: 5)
                Image(systemName: "mappin.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.red)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundColor(.red)
                .offset(x: 0, y: -5)
            
            Text($place.wrappedValue.rank.ordinal)
                .font(.caption2)
            
        }
        .onTapGesture(perform: action)
    }
}
