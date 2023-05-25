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

struct CoordinateWrapper: Hashable, Equatable {
    let coordinate: CLLocationCoordinate2D

    static func ==(lhs: CoordinateWrapper, rhs: CoordinateWrapper) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}

struct MapView: UIViewRepresentable {
    @ObservedObject var locationViewModel: LocationViewModel
    @Binding var currentDestination: LocationPlace?
    @Binding var showRoute: Bool
    @Binding var userTrackingMode: MKUserTrackingMode
    @Binding var isShowAnnotationOpen: Bool
    @Binding var currentAnnotation: CustomAnnotation?
    
    private var locationPlaces: [LocationPlace] {
        locationViewModel.locationPlaces
    }
    @State private var annotations: [MKPointAnnotation] = []
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsCompass = false
                
        // Add compass button
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.frame.origin = CGPoint(x: 20, y: 20)
        compassButton.compassVisibility = .visible
        mapView.addSubview(compassButton)
        
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
        // Get the current set of annotation coordinates
        let currentAnnotationCoordinates = Set(mapView.annotations.compactMap { ($0 as? CustomAnnotation)?.coordinateWrapper })
        
        // Get the new set of annotation coordinates
        let newAnnotationCoordinates = Set(locationPlaces.map { CoordinateWrapper(coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)) })
        
        // Find the coordinates that are new and not already present
        let addedCoordinates = newAnnotationCoordinates.subtracting(currentAnnotationCoordinates)
        
        // Find the coordinates that have been removed
        let removedCoordinates = currentAnnotationCoordinates.subtracting(newAnnotationCoordinates)
        
        // Create and add new annotations for the added coordinates
        for place in locationPlaces {
            let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            let coordinateWrapper = CoordinateWrapper(coordinate: coordinate)
            
            if addedCoordinates.contains(coordinateWrapper) {
                let annotation = CustomAnnotation(coordinate: coordinate, place: place)
                annotation.title = place.name
                mapView.addAnnotation(annotation)
            }
        }
        
        // Remove annotations for the removed coordinates
        for annotation in mapView.annotations {
            if let customAnnotation = annotation as? CustomAnnotation,
               let coordinateWrapper = customAnnotation.coordinateWrapper,
               removedCoordinates.contains(coordinateWrapper) {
                mapView.removeAnnotation(customAnnotation)
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
//            print("add route overlay")
            
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
        renderer.strokeColor = UIColor(red: (CGFloat(21) / 255.0), green: (CGFloat(158) / 255.0), blue: (CGFloat(254) / 255.0), alpha: 1.0)
        renderer.lineWidth = 4.0
        return renderer
    }
    
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
                annotationView?.markerTintColor = UIColor(Color("ColorMosque"))
                annotationView?.glyphImage = UIImage(named: "mosque")
            case "minimarket":
                annotationView?.markerTintColor = UIColor(Color("ColorMinimarket"))
            annotationView?.glyphImage = UIImage(named: "minimarket")
            case "gas-station":
                annotationView?.markerTintColor = UIColor(Color("ColorGasStation"))
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
//        if let annotationView = mapView.view(for: userLocation) {
//            annotationView.transform = CGAffineTransform(rotationAngle: CGFloat(heading).toRadians())
//        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? CustomAnnotation else {
            return
        }
        
        // Handle annotation click
        parent.isShowAnnotationOpen = true
        parent.currentAnnotation = annotation
    }
}


// Custom annotation classes
class CustomAnnotation: MKPointAnnotation {
    var identifier: String?
    let place: LocationPlace
    let coordinateWrapper: CoordinateWrapper?
    
    init(coordinate: CLLocationCoordinate2D, place: LocationPlace) {
        self.place = place
        self.coordinateWrapper = CoordinateWrapper(coordinate: coordinate)
        super.init()
        self.coordinate = coordinate
    }
}

class CustomPointAnnotation: MKPointAnnotation {
    var identifier: String?
    var customTitle: String?
    var type: String?
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
