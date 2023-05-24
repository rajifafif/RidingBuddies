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
            if let customAnnotation = annotation as? CustomPointAnnotation,
               let identifier = customAnnotation.identifier,
               !locationPlaces.contains(where: { $0.id.uuidString == identifier }) {
                outdatedAnnotations.append(customAnnotation)
            }
        }
        mapView.removeAnnotations(outdatedAnnotations)
        
        // Update existing annotations and add new ones
        for place in locationPlaces {
            let annotation = mapView.annotations.first { (annotation) -> Bool in
                if let customAnnotation = annotation as? CustomPointAnnotation,
                   let identifier = customAnnotation.identifier {
                    return identifier == place.id.uuidString
                }
                return false
            }
            
            if let existingAnnotation = annotation as? CustomPointAnnotation {
                existingAnnotation.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            } else {
                var newAnnotation: MKAnnotation?
                
                switch place.type {
                case "mosque":
                    newAnnotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), place: place)
                case "alfamart":
                    newAnnotation = MinimarketAnnotation(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), place: place)
                case "gas-station":
                    newAnnotation = GasStationAnnotation(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), place: place)
                default:
                    break
                }
                
                if let newAnnotation = newAnnotation {
                    mapView.addAnnotation(newAnnotation)
                }
            }
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
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? GasStationAnnotation {
            let marker1AnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "GasStationAnnotation")
            if let image = UIImage(named: "gas-station") {
                let resizedImage = resizeImage(image, targetSize: CGSize(width: 40, height: 40)) // Set the desired size
                marker1AnnotationView.image = resizedImage
                return marker1AnnotationView
            }
        } else if let annotation = annotation as? MosqueAnnotation {
            let marker1AnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "MosqueAnnotation")
            if let image = UIImage(named: "mosque") {
                let resizedImage = resizeImage(image, targetSize: CGSize(width: 40, height: 40)) // Set the desired size
                marker1AnnotationView.image = resizedImage
                return marker1AnnotationView
            }
        } else if let annotation = annotation as? MinimarketAnnotation {
            let marker1AnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "MinimarketAnnotation")
            if let image = UIImage(named: "minimarket") {
                let resizedImage = resizeImage(image, targetSize: CGSize(width: 40, height: 40)) // Set the desired size
                marker1AnnotationView.image = resizedImage
                return marker1AnnotationView
            }
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
    let place: LocationPlace
    
    init(coordinate: CLLocationCoordinate2D, place: LocationPlace) {
        self.coordinate = coordinate
        self.place = place
        super.init()
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
