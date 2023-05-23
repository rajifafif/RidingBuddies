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

struct MapView: UIViewRepresentable {
    @ObservedObject var locationViewModel: LocationViewModel
    @Binding var destinationCoordinate: CLLocationCoordinate2D?
    @Binding var showRoute: Bool
    @Binding var userTrackingMode: MKUserTrackingMode
    
    @Binding var locationPlaces: [LocationPlace]
    
    func makeUIView(context: Context) -> MKMapView {
        print("Debug : makeUIView")
    
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Set Default Tracking Mode
        mapView.userTrackingMode = userTrackingMode
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("Debug : updateUIView")
    
        // Update Tracking Mode when updated
        uiView.userTrackingMode = userTrackingMode
        
//        uiView.removeAnnotations(uiView.annotations)
//
//        for place in locationPlaces {
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
//            annotation.title = place.name
//            uiView.addAnnotation(annotation)
//        }
        
//        if let coordinate = locationViewModel.currentLocation?.coordinate {
////            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
//
//            // Remove previous annotations
//            uiView.removeAnnotations(uiView.annotations)
////
////            // Current Position Annotation
////            let currentPosition = CustomAnnotation(coordinate: coordinate)
////
////            // Add custom annotations to the map view
////            uiView.addAnnotations([currentPosition])
////
//            for place in locationPlaces {
//                let annotation = MKPointAnnotation()
//                annotation.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
//                annotation.title = place.name
//                uiView.addAnnotation(annotation)
//            }
//
//        }

//        if let destinationCoordinate = destinationCoordinate, showRoute {
//            showDirections(on: uiView, to: destinationCoordinate)
//        } else {
//            uiView.removeOverlays(uiView.overlays)
//        }
    }
    
    private func addAnnotations(to mapView: MKMapView) {
        for place in locationPlaces {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            annotation.title = place.name
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        print("Debug : makeCoordinator")
    
        return Coordinator(self)
    }
    
    // Function to show directions from user's current location to the destination coordinate
    private func showDirections(on mapView: MKMapView, to destinationCoordinate: CLLocationCoordinate2D) {
        print("Debug : showDirections")
    
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
