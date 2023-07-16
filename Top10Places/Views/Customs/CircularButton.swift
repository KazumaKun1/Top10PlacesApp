//
//  CurrentLocationButton.swift
//  Top10Places
//
//  Created by Arviejhay on 7/13/23.
//

import SwiftUI

/**
 A reusable button view to show a circle button onto the screen that's customizable such as the image and the action when the button is tapped.
 
 ```
     CircularButton(retrievalStatus: $viewModel.retrievalStatus, imageName: "list.bullet") {
         withAnimation {
             showPlaceListPopup.toggle()
         }
     }
 ```
 
 - parameters:
    - retrievalStatus: represents the status of the retrieval for setting the user interaction of the button whenever it should be enabled or disabled.
    - imageName: represents the image to be used in the button.
    - action: the action when the button is tapped.
 
 */

struct CircularButton: View {
    var retrievalStatus: Binding<LocationRetrievalState>
    
    var imageName: String
    var action: () -> Void
    
    init(retrievalStatus: Binding<LocationRetrievalState> = .constant(.unknown), imageName: String, action: @escaping () -> Void) {
        self.retrievalStatus = retrievalStatus
        self.imageName = imageName
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: imageName)
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .background(retrievalStatus.wrappedValue == .ongoing ? .gray : .white)
                .clipShape(Circle())
                .shadow(color: .gray, radius: 3, x: 0, y: 2)
                .disabled(retrievalStatus.wrappedValue == .ongoing)
        }
    }
}
