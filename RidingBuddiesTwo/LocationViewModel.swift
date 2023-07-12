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
        let status = locationManager.authorizationStatus
            switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                showLocationPermissionDeniedAlert()
            case .authorizedWhenInUse, .authorizedAlways:
                startUpdatingLocation()
            @unknown default:
                showLocationServicesDisabledAlert()
            }
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
    
    private func showLocationPermissionDeniedAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let alert = UIAlertController(
            title: "Location Permission Denied",
            message: "To enable location services, please go to Settings and allow access to your location.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        window.rootViewController?.present(alert, animated: true)
    }
    
    private func showLocationServicesDisabledAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let alert = UIAlertController(
            title: "Location Services Disabled",
            message: "Please enable location services in your device settings to use this app.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        window.rootViewController?.present(alert, animated: true)
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
    
    func fetchFixPlaces() {
        addToPlaces(locationPlaces: [
            LocationPlace(
                name: "Gate B",
                latitude: -6.289114477903174,
                longitude: 106.77528123586164,
                type: "gas-station",
                distanceInKm: 0),
            LocationPlace(
                name: "Gate A",
                latitude: -6.289089059910621,
                longitude: 106.77436374276293,
                type: "gas-station",
                distanceInKm: 0),
            LocationPlace(
                name: "Gate D",
                latitude: -6.289425650764598,
                longitude: 106.77448779492995,
                type: "gas-station",
                distanceInKm: 0),
            LocationPlace(
                name: "Gate F",
                latitude: -6.289442980188797,
                longitude: 106.7753621950688,
                type: "gas-station",
                distanceInKm: 0),
            LocationPlace(
                name: "Lift Gate B",
                latitude: -6.289442980188797,
                longitude: 106.7753621950688,
                type: "gas-station",
                distanceInKm: 0),
            LocationPlace(
                name: "Lift 1 Lagi",
                latitude: -6.28940818503227,
                longitude: 106.77524469012467,
                type: "gas-station",
                distanceInKm: 0),
        ])
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
