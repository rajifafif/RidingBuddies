//
//  LocationViewModel.swift
//  RidingBuddiesTwo
//
//  Created by Rajif Afif on 23/05/23.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: CLHeading?
    @Published var locationPlaces: [LocationPlace] = []
    @Published var searchNearestLocationIsLoading: Bool = false
    
    @Published var searchResults: [LocationPlace] = []
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingHeading()
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            startUpdatingLocation()
        } else {
            stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func fetchNearestByString(queryString: String, completion: @escaping ([LocationPlace]) -> Void) {
        guard let currentLocation = currentLocation else {
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
//                print(MKMapItem.forCurrentLocation())
                let name = mapItem.name
                let latitude = mapItem.placemark.coordinate.latitude
                let longitude = mapItem.placemark.coordinate.longitude
                let distanceInKm = CalculateDistance(sourceCoordinate: currentLocation.coordinate, destinationCoordinate: mapItem.placemark.coordinate) / 1000
                
//                print(distanceInKm)
                
                return LocationPlace(name: name ?? "", latitude: latitude, longitude: longitude, type: "", distanceInKm: distanceInKm)
            }
            
            completion(locationPlaces)
        }
    }
    
    func addToPlaces(locationPlaces: [LocationPlace]) {
        DispatchQueue.main.async {
            self.locationPlaces = locationPlaces
        }
    }
    
    func fetchNearestGasStations() {
        self.searchNearestLocationIsLoading = true
        var _ = fetchNearestByString(queryString: "gas station") { locationPlaces in
            let places = locationPlaces.compactMap { locationPlace -> LocationPlace? in
                // Add Type
                return LocationPlace(
                    name: locationPlace.name,
                    latitude: locationPlace.latitude,
                    longitude: locationPlace.longitude,
                    type: "gas-station",
                    distanceInKm: locationPlace.distanceInKm)
            }
            
            self.addToPlaces(locationPlaces: places)
            self.searchNearestLocationIsLoading = false
        }
    }
    
    func fetchNearestMosque() {
        self.searchNearestLocationIsLoading = true
        var _ = fetchNearestByString(queryString: "Mosque") { locationPlaces in
            let places = locationPlaces.compactMap { locationPlace -> LocationPlace? in
                // Add Type
                return LocationPlace(
                    name: locationPlace.name,
                    latitude: locationPlace.latitude,
                    longitude: locationPlace.longitude,
                    type: "mosque",
                    distanceInKm: locationPlace.distanceInKm)
            }
            
            self.addToPlaces(locationPlaces: places)
            self.searchNearestLocationIsLoading = false
        }
    }
    
    func fetchNearestMinimarket() {
        self.searchNearestLocationIsLoading = true
        var _ = fetchNearestByString(queryString: "indomaret") { locationPlaces in
            let places = locationPlaces.compactMap { locationPlace -> LocationPlace? in
                // Add Type
                return LocationPlace(
                    name: locationPlace.name,
                    latitude: locationPlace.latitude,
                    longitude: locationPlace.longitude,
                    type: "minimarket",
                    distanceInKm: locationPlace.distanceInKm)
            }
            
            self.addToPlaces(locationPlaces: places)
            self.searchNearestLocationIsLoading = false
        }
    }
    
    func searchDestination(queryString: String){
        
//        DispatchQueue.main.async {
//            self.searchResults = []
//        }
//        
        var _ = fetchNearestByString(queryString: queryString) { locationPlaces in
            let foundDestinations = locationPlaces.compactMap { locationPlace -> LocationPlace? in
                // Add Type
                return LocationPlace(
                    name: locationPlace.name,
                    latitude: locationPlace.latitude,
                    longitude: locationPlace.longitude,
                    type: "",
                    distanceInKm: locationPlace.distanceInKm)
            }
            
//            self.searchResults = foundDestinations
            
            DispatchQueue.main.async {
                self.searchResults = foundDestinations
            }
        }
    }
}


func CalculateDistance(sourceCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) -> CLLocationDistance {
    let sourceLocation = CLLocation(latitude: sourceCoordinate.latitude, longitude: sourceCoordinate.longitude)
    let destinationLocation = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)

    return sourceLocation.distance(from: destinationLocation)
}

func distanceDoubleToString(distance: Double?) -> String {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.maximumFractionDigits = 2
    
    if let distance = distance {
        let distanceNumber = NSNumber(value: distance)
        if let stringValue = numberFormatter.string(from: distanceNumber) {
            return stringValue
        }
    }
    
    return "-"
}

func estimateInMinutes(distanceInKm: Double?) -> String {
    let averageMotorcycleSpeed = 52.0 // km/h
    
    if let distance = distanceInKm {
        let estimatedTimeInHours = distance / averageMotorcycleSpeed
        let estimatedTimeInMinutes = estimatedTimeInHours * 60
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        
        if let stringValue = numberFormatter.string(from: NSNumber(value: estimatedTimeInMinutes)) {
            return stringValue
        }
    }
    
    return "-"
}
