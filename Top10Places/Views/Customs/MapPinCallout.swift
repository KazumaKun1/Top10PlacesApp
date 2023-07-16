//
//  MapPinCallout.swift
//  Top10Places
//
//  Created by Arviejhay on 7/13/23.
//

import SwiftUI

/**
 A callout view to represent the information on the screen. Mostly it's used when an annotation has been tapped.
 
 ```
     MapPinCallout(place: selectedPlace, action: {
         withAnimation {
             self.selectedPlace = nil
         }
     })
 ```
 
 - parameters:
    - place: An object that has a place information such as the name or place to be display in the callout view.
    - action: An action to do when the callout view is tapped.
 
 */

struct MapPinCallout: View {
    var place: Place
    
    var action: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            Text(place.rank.ordinal)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing, .bottom])
            Text(place.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding([.leading, .trailing, .bottom])
            Text(place.address.label)
                .font(.callout)
                .padding(.bottom, 20)
                .multilineTextAlignment(.center)
            Text("\(place.distance) meters away from your current location ")
                .font(.callout)
                .padding(.bottom, 10)
                .multilineTextAlignment(.center)
            HStack {
                Text("\(place.position.lat)° latitude, \(place.position.lng)° longitude")
                    .font(.footnote)
                    .padding(.bottom, 10)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .foregroundColor(.white)
        .background(.blue)
        .cornerRadius(20)
        .frame(width: 300)
        .shadow(radius: 3, x: 0, y: 5)
        .onTapGesture(perform: action)
    }
}
