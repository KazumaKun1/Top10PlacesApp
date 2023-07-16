//
//  GroupedPlacesListView.swift
//  Top10Places
//
//  Created by Arviejhay on 7/15/23.
//

import SwiftUI

/**
 A view that shows a list similar to the design of 'PlacesListView' to show the places that have the same coordinates.
 
 ```
 GroupedPlacesListView(places: viewModel.places.getGroupedAnnotations(for: selectedPlace) ?? [Place]()) { place in
     withAnimation {
         self.selectedPlace = place
         showGroupedPlacesListPopup = false
     }
 }
 ```
 
 - parameters:
    - places: test.
    - action: test
 
 */

struct GroupedPlacesListView: View {
    var places: [Place]
    
    var action: (Place) -> Void
    
    var body: some View {
        VStack {
            List {
                ForEach(places) { place in
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.and.ellipse")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Image(systemName: "\(place.rank.rawValue).circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                Text(place.title)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                            }
                            Text(place.address.label)
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 10, height: 10)
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        action(place)
                    }
                }
            }
        }
        .frame(width: 350, height: 350)
        .cornerRadius(20)
        .shadow(radius: 3, x: 0, y: 3)
    }
}
