//
//  ContentView.swift
//  RidingBuddiesTwo
//
//  Created by Rajif Afif on 17/05/23.
//

import SwiftUI
import MapKit

struct LocationPlace: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let type: String?
}

struct ContentView: View {
//    @StateObject private var coordinator = Coordinator()
    
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    @State private var showRoute = false
    
    
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var locationPlaces: [LocationPlace] = []
    
    //    @State private var gasStations: [GasStation] = []
    
    @State private var searchText = ""
    @State private var isShowingSheet = false
    @State private var searchResults: [LocationPlace] = []
    
    @State private var currentDestination: LocationPlace?
    @State private var userTrackingMode: MKUserTrackingMode = .followWithHeading
    
    var body: some View {
        VStack {
            ZStack{
                MapView(
                    locationViewModel: locationViewModel,
//                    destinationCoordinate: $destinationCoordinate,
                    currentDestination: $currentDestination,
                    showRoute: $showRoute,
                    userTrackingMode: $userTrackingMode
                )
                .edgesIgnoringSafeArea(.all)
                
                HStack{
                    Spacer()
                    
                    VStack{
                        Button(action: {
                            locationViewModel.fetchNearestMosque()
                        }) {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 70, height: 70)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                        }
                        
                        Button(action: {
                            locationViewModel.fetchNearestMinimarket()
                        }) {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 70, height: 70)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                        }
                        
                        Button(action: {
                            locationViewModel.fetchNearestGasStations()
                        }) {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 70, height: 70)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Button action
                            print("Toggle Route")
                            showRoute = !showRoute
                            
                        }) {
                            Circle()
                                .frame(width: 70)
                                .foregroundColor(.white)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                        }
                        
                        Button(action: {
                            toggleUserTrackingMode()
                        }) {
                            Circle()
                                .frame(width: 70)
                                .foregroundColor(.white)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                        }
                        
                        Spacer()
                            .frame(height: 120)
                    }
                    .padding()
                }
                
                if (locationViewModel.searchNearestLocationIsLoading) {
                    LoadingView()
                }
                
                if (currentDestination != nil) {
                    ActiveDestinationComponent(currentDestination: $currentDestination)
                } else {
                    DestinationSearchView(
                        searchText: $searchText,
                        onSearch: {
                            locationViewModel.searchDestination(queryString: searchText)
                        },
                        currentDestination: $currentDestination,
                        showRoute: $showRoute
                    )
                    .environmentObject(locationViewModel)
                }
            }
        }
        .onAppear {
            locationViewModel.requestAuthorization()
            locationViewModel.startUpdatingLocation()
        }
    }
    
    struct LoadingView: View {
        var body: some View {
            VStack {
                Text("Loading . . .")
            }
        }
    }
    
    func toggleUserTrackingMode() {
        switch userTrackingMode {
        case .none:
            userTrackingMode = .follow
        case .follow:
            userTrackingMode = .followWithHeading
        case .followWithHeading:
            userTrackingMode = .none
        @unknown default:
            userTrackingMode = .followWithHeading
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
