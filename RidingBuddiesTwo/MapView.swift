//
//  MapView.swift
//  RidingBuddiesTwo
//
//  Created by Rajif Afif on 17/05/23.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

extension CGFloat {
    func toRadians() -> CGFloat {
        return self * CGFloat.pi / 180.0
    }
}

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: CLHeading?
    
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
            print("Updating currentLocation")
            currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}


struct MapView: UIViewRepresentable {
    @ObservedObject var locationViewModel: LocationViewModel
    @Binding var destinationCoordinate: CLLocationCoordinate2D?
    @Binding var showRoute: Bool
    
    @Binding var locationPlaces: [LocationPlace]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        if let coordinate = locationViewModel.currentLocation?.coordinate {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
            mapView.setRegion(region, animated: true)
        }
        
        // Add pinch gesture recognizer for zooming
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinchGesture(_:)))
        mapView.addGestureRecognizer(pinchGesture)
        
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("updateUiView")
        // Update the map view here if needed
        if let coordinate = locationViewModel.currentLocation?.coordinate {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
            uiView.setRegion(region, animated: true)


            // Remove previous annotations
            uiView.removeAnnotations(uiView.annotations)

            // Current Position Annotation
            let currentPosition = CustomAnnotation(coordinate: coordinate)
            
            let currentPosition2 = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: 2.1, longitude: 3.2))

            // Add custom annotations to the map view
            uiView.addAnnotations([currentPosition])

            for place in locationPlaces {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
                annotation.title = place.name
                uiView.addAnnotation(annotation)
            }

        }

        if let destinationCoordinate = destinationCoordinate, showRoute {
            showDirections(on: uiView, to: destinationCoordinate)
        } else {
            uiView.removeOverlays(uiView.overlays)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // Function to show directions from user's current location to the destination coordinate
    private func showDirections(on mapView: MKMapView, to destinationCoordinate: CLLocationCoordinate2D) {
        guard let userCoordinate = locationViewModel.currentLocation?.coordinate else {
            return
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                return
            }
            
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlay(route.polyline, level: .aboveRoads)
        }
    }
    
    func reCenterMap(_ uiView: MKMapView) {
        if let coordinate = locationViewModel.currentLocation?.coordinate {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
            uiView.setRegion(region, animated: true)
        }
    }
    
    // MapView Coordinator to handle delegate methods
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        // Route
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 3.0
            return renderer
        }
        
        // Custom Marker Image
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is CustomAnnotation {
                let currentPositionAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "CurrentPositionAnnotation")
                currentPositionAnnotationView.image = UIImage(named: "currentPosition")
                return currentPositionAnnotationView
            } else if annotation is CustomAnnotation1 {
                let marker1AnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Marker1Annotation")
                marker1AnnotationView.image = UIImage(named: "marker1_marker_image")
                return marker1AnnotationView
            } else if annotation is CustomAnnotation2 {
                let marker2AnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Marker2Annotation")
                marker2AnnotationView.image = UIImage(named: "marker2_marker_image")
                return marker2AnnotationView
            }
            
            return nil
        }
        
        // Update
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard let heading = parent.locationViewModel.currentHeading?.trueHeading else {
                return
            }
            
            // Rotate the current position marker based on the user's heading
            if let annotationView = mapView.view(for: userLocation) {
                annotationView.transform = CGAffineTransform(rotationAngle: CGFloat(heading).toRadians())
            }
        }
        
        
        @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else {
                return
            }

            if gesture.state == .changed {
                let scale = min(max(gesture.scale, 0.5), 5) // Restrict the scale factor within a reasonable range
                let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta / Double(scale),
                                            longitudeDelta: mapView.region.span.longitudeDelta / Double(scale))
                let region = MKCoordinateRegion(center: mapView.region.center, span: span)
                mapView.setRegion(region, animated: true)
            }
        }

    }
    
    // Custom annotation classes
    class CustomAnnotation: NSObject, MKAnnotation {
        let coordinate: CLLocationCoordinate2D
        
        init(coordinate: CLLocationCoordinate2D) {
            self.coordinate = coordinate
            super.init()
        }
    }
    
    class CustomAnnotation1: NSObject, MKAnnotation {
        let coordinate: CLLocationCoordinate2D
        
        init(coordinate: CLLocationCoordinate2D) {
            self.coordinate = coordinate
            super.init()
        }
    }
    
    class CustomAnnotation2: NSObject, MKAnnotation {
        let coordinate: CLLocationCoordinate2D
        
        init(coordinate: CLLocationCoordinate2D) {
            self.coordinate = coordinate
            super.init()
        }
    }
    
}
