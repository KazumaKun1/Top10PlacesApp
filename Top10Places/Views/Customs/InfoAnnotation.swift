//
//  InfoAnnotation.swift
//  Top10Places
//
//  Created by Arviejhay on 7/14/23.
//

import SwiftUI

/**
 A view to represent an info annotation in the map if there more than one places that have the same coordinates.
 
 ```
 InfoAnnotation(count: viewModel.places.getGroupedAnnotations(for: place.wrappedValue)!.count) {
     withAnimation {
         viewModel.goToPlaceAnnotation(place: place.wrappedValue)
         showGroupedPlacesListPopup = true
         selectedPlace = place.wrappedValue
     }
 }
 ```
 
 - parameters:
    - places: represents the places that are in the same place or same coordinates.
    - action: the action when the view is tapped.
 
 */

struct InfoAnnotation: View {
    var places: [Place]
    
    let action: () -> Void

    var body: some View {
        VStack {
            Image(systemName: "info")
                .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(.red)
            .cornerRadius(20)
            .overlay(
                Text("\(places.count)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(.blue)
                    .clipShape(Circle())
                    .offset(x: 12, y: -12))
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundColor(.red)
                .offset(x: 0, y: -5)
            
            Text("")
                .font(.caption2)
        }
        .shadow(radius: 3, x: 0, y: 5)
        .onTapGesture(perform: action)
    }
}
