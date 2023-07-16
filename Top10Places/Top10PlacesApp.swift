//
//  Top10PlacesApp.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import SwiftUI

@main
struct Top10PlacesApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
