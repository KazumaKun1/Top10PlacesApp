//
//  StatusView.swift
//  Top10Places
//
//  Created by Arviejhay on 7/14/23.
//

import SwiftUI

/**
 It shows the current status of the process or retrieving from location service or API.
 
 
 ```
    StatusView(retrievalStatus: $viewModel.retrievalStatus)
 ```
 
 - parameters:
    - retrievalStatus: represents the status of retrieving of location/API or processing that is used to convey information from the user about the status of the app..
 
 */

struct StatusView: View {
    @Binding var retrievalStatus: LocationRetrievalState
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Status: ")
                .font(.caption)
            if retrievalStatus != .ongoing {
                Image(systemName: retrievalStatus.getIcon().iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .foregroundColor(retrievalStatus.getIcon().color)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 15, height: 15)
            }
        }
        .padding([.top, .bottom], 5)
        .padding([.leading, .trailing], 15)
        .background(.white)
        .cornerRadius(10)
        .shadow(radius: 3, x: 0, y: 2)
    }
}
