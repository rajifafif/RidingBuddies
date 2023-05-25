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
    let distanceInKm: Double?
}

struct ContentView: View {
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    @State private var showRoute = false
    
    
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var locationPlaces: [LocationPlace] = []
    
    @State private var searchText = ""
    @State private var isShowingSheet = false
    @State private var searchregResults: [LocationPlace] = []
    
    @State private var currentDestination: LocationPlace?
    @State private var userTrackingMode: MKUserTrackingMode = .followWithHeading
    
    @State private var isShowAnnotationOpen: Bool = false
    @State private var currentAnnotation: CustomAnnotation?
    
    var body: some View {
        VStack {
            ZStack{
                MapView(
                    locationViewModel: locationViewModel,
                    currentDestination: $currentDestination,
                    showRoute: $showRoute,
                    userTrackingMode: $userTrackingMode,
                    isShowAnnotationOpen: $isShowAnnotationOpen,
                    currentAnnotation: $currentAnnotation
                )
                .gesture(DragGesture()
                    .onChanged { _ in
                        // Perform any additional actions when dragging starts
                        userTrackingMode = .none
                    }
                )
                .edgesIgnoringSafeArea(.all)
                
                HStack{
                    Spacer()
                    
                    VStack{
                        HStack{
                            Spacer()
                            
                            VStack{
                                Button(action: {
                                    locationViewModel.fetchNearestMosque()
                                }) {
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(Color("ColorMosque"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white, lineWidth: 1)
                                            )
                                        Image("mosque")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 30)
                                    }
                                }
                                
                                Button(action: {
                                    locationViewModel.fetchNearestMinimarket()
                                }) {
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(Color("ColorMinimarket"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white, lineWidth: 1)
                                            )
                                        Image("minimarket")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 30)
                                    }
                                }
                                
                                Button(action: {
                                    locationViewModel.fetchNearestGasStations()
                                }) {
                                    ZStack{
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(Color("ColorGasStation"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white, lineWidth: 1)
                                            )
                                        Image("gas-station")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if userTrackingMode == .none {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    toggleUserTrackingMode()
                                }) {
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 25)
                                            .frame(width: 150, height: 50)
                                            .foregroundColor(.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(Color.gray, lineWidth: 1)
                                            )
                                        
                                        HStack{
                                            Text("Re-center")
                                            
                                            Image("currentPosition")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(height: 30)
                                        }
                                    }
                                }
                            }
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            Spacer().frame(height: currentDestination != nil ? 100 : 80)
                        }
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
        .modifier(KeyboardAdaptive())
        .onAppear {
            locationViewModel.requestAuthorization()
        }
        .sheet(isPresented: $isShowAnnotationOpen) {
            if (currentAnnotation != nil) {
                Text(currentAnnotation?.place.name ?? "Yeet")
                Button(action: {
                    currentDestination = currentAnnotation?.place
                    showRoute = true
                    isShowAnnotationOpen = false
                }) {
                    Text("Set Destination")
                }
            } else {
                Text("No Annotation Selected")
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
    
    func toggleUserTrackingMode() {
        switch userTrackingMode {
        case .none:
            userTrackingMode = .followWithHeading
        case .followWithHeading:
            userTrackingMode = .none
        case .follow:
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

import Combine

final class KeyboardResponder: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var keyboardHeight: CGFloat = 0

    func addObserver() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { notification -> CGFloat? in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return frame.height
            }
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
    }

    func removeObserver() {
        cancellables.removeAll()
    }
}

struct KeyboardAdaptive: ViewModifier {
    @ObservedObject private var keyboard = KeyboardResponder()

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboard.keyboardHeight)
            .edgesIgnoringSafeArea(keyboard.keyboardHeight > 0 ? .bottom : [])
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboard.addObserver()
                }
            }
            .onDisappear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboard.removeObserver()
                }
            }
    }
}
