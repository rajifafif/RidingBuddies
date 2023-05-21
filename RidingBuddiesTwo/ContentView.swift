//
//  ContentView.swift
//  RidingBuddiesTwo
//
//  Created by Rajif Afif on 17/05/23.
//

import SwiftUI
import MapKit

struct GasStation: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
}

struct ContentView: View {
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    @State private var showRoute = false
    
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var gasStations: [GasStation] = []
    
    @State private var isShowingSheet = false
    
    var body: some View {
        VStack {
            ZStack{
                MapView(locationViewModel: locationViewModel, destinationCoordinate: $destinationCoordinate, showRoute: $showRoute, gasStations: $gasStations)
                    .edgesIgnoringSafeArea(.all)
                
                HStack{
                    Spacer()
                    
                    VStack{
                        Button(action: {
                            // Button action
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
                            // Button action
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
                            // Button action
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
                            // Button action
                            isShowingSheet = true
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
                .sheet(isPresented: $isShowingSheet) {
                    // Content of the sheet view
                    SheetView()
                        .presentationDetents([.large, .medium, .fraction(0.75)])
                }
                
                DestinationSearchView()
            }
        }
        .onAppear {
            locationViewModel.requestAuthorization()
            locationViewModel.startUpdatingLocation()
        }
    }
    
    func fetchNearestGasStations() {
        guard let currentLocation = locationViewModel.currentLocation else {
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "gas station"
        request.region = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let mapItems = response?.mapItems else {
                print("Error searching for gas stations: \(error?.localizedDescription ?? "")")
                return
            }
            
            let gasStations = mapItems.compactMap { mapItem -> GasStation? in
                let name = mapItem.name
                let latitude = mapItem.placemark.coordinate.latitude
                let longitude = mapItem.placemark.coordinate.longitude
                
                return GasStation(name: name ?? "Gas Station Name", latitude: latitude, longitude: longitude)
            }
            
            DispatchQueue.main.async {
                self.gasStations = gasStations
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
