//
//  Top10PlacesApp.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import SwiftUI

@main
struct Top10PlacesApp: App {
    @StateObject var viewModel = RankingPlacesViewModel(mapService: MapService())
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
        }
    }
}
