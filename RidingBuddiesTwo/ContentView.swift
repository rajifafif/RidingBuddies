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
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    @State private var showRoute = false
    
    
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var locationPlaces: [LocationPlace] = []
    @State private var searchLocationIsLoading: Bool = false
    
//    @State private var gasStations: [GasStation] = []
    
    @State private var searchText = ""
    @State private var isShowingSheet = false
    @State private var searchResults: [LocationPlace] = []
    
    @State private var currentDestination: LocationPlace?
    
    var body: some View {
        VStack {
            ZStack{
                MapView(locationViewModel: locationViewModel, destinationCoordinate: $destinationCoordinate, showRoute: $showRoute, locationPlaces: $locationPlaces)
                    .edgesIgnoringSafeArea(.all)
                
                HStack{
                    Spacer()
                    
                    VStack{
                        Button(action: {
                            fetchNearestMosque()
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
                            fetchNearestMinimarket()
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
                            fetchNearestGasStationsTwo()
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
                            print("Showing Route")
                            showRoute = true
                            
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
                            locationViewModel.requestAuthorization()
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
//                .sheet(isPresented: $isShowingSheet) {
//                    // Content of the sheet view
//                    SheetView()
//                        .presentationDetents([.large, .medium, .fraction(0.75)])
//                }
                
                if (searchLocationIsLoading) {
                    LoadingView()
                }
                
                if (currentDestination != nil) {
                    ActiveDestinationComponent(currentDestination: currentDestination)
                } else {
                    DestinationSearchView(searchText: $searchText, searchResults: $searchResults, onSearch: {
                        searchDestination(queryString: searchText)
                    }, currentDestination: $currentDestination)
                }
            }
        }
        .onAppear {
            locationViewModel.requestAuthorization()
            locationViewModel.startUpdatingLocation()
        }
    }
    
    func fetchNearestByString(queryString: String, completion: @escaping ([LocationPlace]) -> Void) {
        guard let currentLocation = locationViewModel.currentLocation else {
            completion([])
            return
        }
        
        var locationPlaces: [LocationPlace] = []
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = queryString
        request.region = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let mapItems = response?.mapItems else {
                print("Error searching for locations: \(error?.localizedDescription ?? "")")
                completion([])
                return
            }
            
            locationPlaces = mapItems.compactMap { mapItem -> LocationPlace? in
                let name = mapItem.name
                let latitude = mapItem.placemark.coordinate.latitude
                let longitude = mapItem.placemark.coordinate.longitude
                
                return LocationPlace(name: name ?? "", latitude: latitude, longitude: longitude, type: "")
            }
            
            completion(locationPlaces)
        }
    }
    
    func addToPlaces(locationPlaces: [LocationPlace]) {
        DispatchQueue.main.async {
            self.locationPlaces = locationPlaces
        }
    }
    
    func fetchNearestGasStationsTwo() {
        searchLocationIsLoading = true
        var _ = fetchNearestByString(queryString: "gas station") { locationPlaces in
            let gasStations = locationPlaces.compactMap { locationPlace -> LocationPlace? in
                // Add Type
                return LocationPlace(name: locationPlace.name, latitude: locationPlace.latitude, longitude: locationPlace.longitude, type: "gas-station")
            }
            
            addToPlaces(locationPlaces: gasStations)
            searchLocationIsLoading = false
        }
    }
    
    func fetchNearestMosque() {
        searchLocationIsLoading = true
        var _ = fetchNearestByString(queryString: "mosque") { locationPlaces in
            let gasStations = locationPlaces.compactMap { locationPlace -> LocationPlace? in
                // Add Type
                return LocationPlace(name: locationPlace.name, latitude: locationPlace.latitude, longitude: locationPlace.longitude, type: "mosque")
            }
            
            addToPlaces(locationPlaces: gasStations)
            searchLocationIsLoading = false
        }
    }
    
    func fetchNearestMinimarket() {
        searchLocationIsLoading = true
        var _ = fetchNearestByString(queryString: "indomaret") { locationPlaces in
            let gasStations = locationPlaces.compactMap { locationPlace -> LocationPlace? in
                // Add Type
                return LocationPlace(name: locationPlace.name, latitude: locationPlace.latitude, longitude: locationPlace.longitude, type: "minimarket")
            }
            
            addToPlaces(locationPlaces: gasStations)
            searchLocationIsLoading = false
        }
    }
    
    func searchDestination(queryString: String){
        
            searchLocationIsLoading = true
            DispatchQueue.main.async {
                self.searchResults = []
            }
        
            var _ = fetchNearestByString(queryString: queryString) { locationPlaces in
                let foundDestinations = locationPlaces.compactMap { locationPlace -> LocationPlace? in
                    // Add Type
                    return LocationPlace(name: locationPlace.name, latitude: locationPlace.latitude, longitude: locationPlace.longitude, type: "gas-station")
                }
                searchLocationIsLoading = false
                
                DispatchQueue.main.async {
                    self.searchResults = foundDestinations
                }
            }
    }
    
    struct SheetView: View {
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            VStack {
                Text("Sheet View")
                    .font(.title)
                    .padding()
                
                Button("Close") {
                    dismiss()
                }
                .padding()
            }
        }
    }
    
    struct LoadingView: View {
        var body: some View {
            VStack {
                Text("Loading . . .")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
