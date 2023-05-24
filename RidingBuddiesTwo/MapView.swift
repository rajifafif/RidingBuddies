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
    @Binding var currentDestination: LocationPlace?
    @Binding var showRoute: Bool
    @Binding var userTrackingMode: MKUserTrackingMode
    
    private var locationPlaces: [LocationPlace] {
        locationViewModel.locationPlaces
    }
    @State private var annotations: [MKPointAnnotation] = []
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Set Default Tracking Mode
        mapView.userTrackingMode = userTrackingMode
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update Tracking Mode when updated
        uiView.userTrackingMode = userTrackingMode
        
        // Update annotations
        updateAnnotations(on: uiView)
        
        // Show route if enabled
        if showRoute, let currentDestination = currentDestination {
            showDirections(on: uiView, to: CLLocationCoordinate2D(latitude: currentDestination.latitude, longitude: currentDestination.longitude))
        } else {
            uiView.removeOverlays(uiView.overlays) // Remove any existing routes
        }
    }
    
    private func updateAnnotations(on mapView: MKMapView) {
        // Remove outdated annotations
        var outdatedAnnotations: [MKAnnotation] = []
        for annotation in mapView.annotations {
            if let customAnnotation = annotation as? CustomAnnotation,
               let identifier = customAnnotation.identifier,
               !locationPlaces.contains(where: { $0.id.uuidString == identifier }) {
                outdatedAnnotations.append(customAnnotation)
            }
        }
        mapView.removeAnnotations(outdatedAnnotations)
        
        // Update existing annotations and add new ones
        for place in locationPlaces {
            let annotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), place: place)
            annotation.title = place.name
//            annotation.subtitle = "subitle brooo"
            mapView.addAnnotation(annotation)
        }
    }
    
    private func showDirections(on mapView: MKMapView, to destinationCoordinate: CLLocationCoordinate2D) {
        guard let userCoordinate = locationViewModel.currentLocation?.coordinate else {
            return
        }
        
        let sourcePlacemark = MKPlacemark(coordinate: userCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destinationMapItem
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                return
            }
            
            // Remove any existing overlays
            mapView.removeOverlays(mapView.overlays)
            
            // Add the new route overlay
            mapView.addOverlay(route.polyline)
            print("add route overlay")
            
            // Zoom the map to fit the route
//            mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
        }
    }
    
    func reCenterMap(_ uiView: MKMapView) {
        if let coordinate = locationViewModel.currentLocation?.coordinate {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
            uiView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        print("Debug : makeCoordinator")
    
        return Coordinator(self)
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
    
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        let scaleFactor = max(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }
    
    // Custom Marker Image
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKUserLocation {
//            // Return nil to use the default annotation view for the user's location
//            return nil
//        } else if let annotation = annotation as? GasStationAnnotation {
//            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "GasStationAnnotation") ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "GasStationAnnotation")
//            annotationView.canShowCallout = true
//            annotationView.tintColor = .red // Set the desired tint color
//            return annotationView
//        } else if let annotation = annotation as? MosqueAnnotation {
//            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "MosqueAnnotation") ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MosqueAnnotation")
//            annotationView.canShowCallout = true
//            annotationView.tintColor = .green // Set the desired tint color
//            return annotationView
//        } else if let annotation = annotation as? MinimarketAnnotation {
//            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "MinimarketAnnotation") ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MinimarketAnnotation")
//            annotationView.canShowCallout = true
//            annotationView.tintColor = .blue // Set the desired tint color
//            return annotationView
//        }
//
//        return nil
//    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let customAnnotation = annotation as? CustomAnnotation else {
            return nil
        }
        
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as? MKMarkerAnnotationView
            annotationView?.annotation = customAnnotation
            annotationView?.canShowCallout = true

        // Customize the marker's appearance based on the annotation type
        //        annotationView?.glyphText = customAnnotation.place.name
        annotationView?.titleVisibility = .visible
        annotationView?.subtitleVisibility = .visible
        
        
        switch customAnnotation.place.type {
            case "mosque":
                annotationView?.markerTintColor = .green
                annotationView?.glyphImage = UIImage(named: "mosque")
            case "minimarket":
                annotationView?.markerTintColor = .orange
            annotationView?.glyphImage = UIImage(named: "minimarket")
            case "gas-station":
                annotationView?.markerTintColor = .blue
            annotationView?.glyphImage = UIImage(named: "gas-station")
            default:
                annotationView?.markerTintColor = .red
        }

        return annotationView
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
class CustomAnnotation: MKPointAnnotation {
    var identifier: String?
    let place: LocationPlace
    
    init(coordinate: CLLocationCoordinate2D, place: LocationPlace) {
        self.place = place
        super.init()
        self.coordinate = coordinate
    }
}

class MosqueAnnotation: CustomAnnotation {
    
}

class MinimarketAnnotation: CustomAnnotation {
    
}

class GasStationAnnotation: CustomAnnotation {
    
}

class CustomPointAnnotation: MKPointAnnotation {
    var identifier: String?
    var customTitle: String?
    var type: String?
}
