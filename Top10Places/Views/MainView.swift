//
//  MainView.swift
//  Top10Places
//
//  Created by Arviejhay on 7/12/23.
//

import SwiftUI
import MapKit

struct MainView: View {
    @ObservedObject var viewModel = RankingPlacesViewModel()
    
    @State var showNeedsPermissionAlert = false
    @State var showPinInfoPopup = false
    @State var showPlaceListPopup = false
    @State var showGroupedPlacesListPopup = false
    
    @State var selectedPlace: Place?

    var body: some View {
        ZStack {
            //MARK: Map
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: $viewModel.places) { place in
                MapAnnotation(coordinate: place.wrappedValue.position.coordinate) {
                    if place.annotationType.wrappedValue == .grouped {
                        InfoAnnotation(places: viewModel.places.getGroupedAnnotations(for: place.wrappedValue)!) {
                            withAnimation {
                                viewModel.goToPlaceAnnotation(place: place.wrappedValue)
                                showGroupedPlacesListPopup = true
                                selectedPlace = place.wrappedValue
                            }
                        }
                    } else if place.annotationType.wrappedValue == .single {
                        MapPinWithTitle(place: place, action: {
                            withAnimation {
                                viewModel.goToPlaceAnnotation(place: place.wrappedValue)
                                selectedPlace = place.wrappedValue
                            }
                        })
                    } else {
                        Color.clear
                            .frame(width: 0, height: 0)
                    }
                }
            }
            .ignoresSafeArea()
            .disabled(selectedPlace != nil)
            
            VStack(alignment: .leading) {
                HStack {
                    //MARK: Place List Button
                    CircularButton(retrievalStatus: $viewModel.retrievalStatus, imageName: "list.bullet") {
                        withAnimation {
                            showPlaceListPopup.toggle()
                        }
                    }
                    
                    //MARK: Status View
                    StatusView(retrievalStatus: $viewModel.retrievalStatus)
                }
                
                if showPlaceListPopup {
                    //MARK: Place List View
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
                }
                
                Spacer()
            }
            .padding(.leading, 15)
            .padding(.top, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack {
                Spacer()
                
                //MARK: Refresh Button
                CircularButton(retrievalStatus: $viewModel.retrievalStatus, imageName: "arrow.clockwise") {
                    withAnimation {
                        viewModel.refreshPlaces()
                        
                        if showPlaceListPopup {
                            showPlaceListPopup = false
                        }
                    }
                }
                .padding(.bottom, 20)

                //MARK: Current Location Button
                CircularButton(retrievalStatus: $viewModel.retrievalStatus, imageName: "location.fill") {
                    withAnimation {
                        viewModel.goToCurrentLocation()
                    }
                }
            }
            .padding(.bottom, 100)
            .padding(.trailing, 15)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            //MARK: Map Callout
            if let selectedPlace = selectedPlace,
                !showGroupedPlacesListPopup {
                ZStack {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                        .onTapGesture(perform: {
                            withAnimation {
                                self.selectedPlace = nil
                            }
                        })
                    MapPinCallout(place: selectedPlace, action: {
                        withAnimation {
                            self.selectedPlace = nil
                        }
                    })
                }
            }
            
            //MARK: Grouped Places List
            if showGroupedPlacesListPopup {
                ZStack {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                        .onTapGesture(perform: {
                            withAnimation {
                                selectedPlace = nil
                                showGroupedPlacesListPopup = false
                            }
                        })
                    
                    if let selectedPlace = selectedPlace {
                        GroupedPlacesListView(places: viewModel.places.getGroupedAnnotations(for: selectedPlace) ?? [Place]()) { place in
                            withAnimation {
                                self.selectedPlace = place
                                showGroupedPlacesListPopup = false
                            }
                        }
                    }
                }
            }
        }
        
        //MARK: Location Permission Required Alert
        .alert("Location Permission Required", isPresented: $viewModel.showNeedsPermissionAlert) {
            Button("Open Settings") {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                
                UIApplication.shared.open(settingsURL)
            }
        } message: {
            Text("Please enable location permission for the app in your device settings in order for us to provide you the list of places.")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
