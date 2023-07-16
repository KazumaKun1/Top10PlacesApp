//
//  PlaceListView.swift
//  Top10Places
//
//  Created by Arviejhay on 7/14/23.
//

import SwiftUI

/**
 A view that shows the list of data in the map. It shows the top 10 places near the user's location and if a place has been tapped. It will show an action
 
 ```
 PlaceListView(places: $viewModel.places) { place in
     withAnimation {
         showPlaceListPopup = false
         viewModel.goToPlaceAnnotation(place: place)
         
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
             withAnimation {
                 selectedPlace = place
             }
         }
     }
 }
 ```
 
 - parameters:
    - places: an array of places that represents the top 10 places retrieved.
    - action: the action when a place has been that in the list
 
 */

struct PlaceListView: View {
    @Binding var places: [Place]
    
    var action: (Place) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading) {
                    NavigationStack {
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
                                            Text("\(place.title)")
                                                .font(.headline)
                                                .multilineTextAlignment(.leading)
                                        }
                                        Text("\(place.distance) meters away from your location")
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
                            .listStyle(.plain)
                        }
                        
                        .navigationTitle("Top 10 places")
                    }
                    
                    Spacer()
                }
                .frame(width: min(geometry.size.width - 40, 300), height: min(geometry.size.height - 40, 300))
                .cornerRadius(20)
                .shadow(radius: 3, x: 0, y: 3)
            }
        }
    }
}
