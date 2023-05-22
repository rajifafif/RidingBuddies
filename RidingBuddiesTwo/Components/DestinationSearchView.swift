//
//  DestinationSearchView.swift
//  RidingBuddiesTwo
//
//  Created by Rajif Afif on 19/05/23.
//

import SwiftUI

struct DestinationSearchView: View {
    @Binding var searchText: String
    @Binding var searchResults: [LocationPlace]
    var onSearch: () -> Void // Callback closure
    @Binding var currentDestination: LocationPlace?
    
    @GestureState private var dragState = CGSize.zero
    @State private var position = CGSize.zero
    @State private var isExpanded = false
    
    @State private var height = 70.0
    
    var body: some View {
        
        VStack{
            Spacer()
            
            ZStack{
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.white)
                    .edgesIgnoringSafeArea(.all)
                    .gesture(
                        DragGesture()
                            .updating($dragState) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    if value.translation.height > 100 {
                                        // Expand the sheet when dragged beyond a threshold
                                        height = 70
                                        isExpanded = false
                                    } else {
                                        // Collapse the sheet
                                        height = UIScreen.main.bounds.height - 100
                                        isExpanded = true
                                    }
                                }
                            }
                    )
                
                VStack{
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.gray)
                        .frame(width: 70, height: 5)
                        .padding(.top)
                    
                    HStack{
                        
                        // Search Input
                        ZStack(alignment: .leading) {
                            if searchText.isEmpty {
                                Text("Search Destination")
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                            }
                            
                            TextField("", text: $searchText)
                                .padding(.horizontal)
                                .foregroundColor(.black)
                                .onTapGesture {
                                    withAnimation {
                                        height = UIScreen.main.bounds.height - 100
                                        isExpanded = true
                                    }
                                }
                        }
                        .frame(height: 40)
                        .background(Color.gray) // Change the background color here
                        .cornerRadius(5)
                        
                        
                        // Search Button
                        Button(action: {
                            withAnimation {
                                height = UIScreen.main.bounds.height - 100
                                isExpanded = true
                            }
                            
                            onSearch()
                        }) {
                            Text("Search")
                        }
                    }
                    .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 1)
                        .foregroundColor(.gray)
                        .opacity(isExpanded ? 1 : 0)
                    
                    
                    ScrollView{
                        
//                        ForEach([1, 2, 3, 4, 5, 6 , 7], id: \.self) { number in
//                            DestinationCardView()
//                        }
                        ForEach(searchResults, id: \.self) { locationPlace in
                            Button(action: {
                                withAnimation {
                                    height = 70
                                    isExpanded = false
                                }
                                
                                currentDestination = locationPlace
                            }) {
                                DestinationCardView(locationPlace: locationPlace)
                            }
                        }
                        
                    }
                    .opacity(isExpanded ? 1 : 0)
                    
//                    Spacer()
                }
            }
            .frame(height: height)
        }
    }
}

struct DestinationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationSearchView(searchText: .constant(""), searchResults: .constant([]), onSearch: {}, currentDestination: .constant(LocationPlace(name: "Default", latitude: 0.3, longitude: 0.3, type: "aksjdn")))
    }
}
