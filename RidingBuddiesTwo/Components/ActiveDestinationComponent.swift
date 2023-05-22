//
//  ActiveDestinationComponent.swift
//  RidingBuddiesTwo
//
//  Created by Rajif Afif on 22/05/23.
//

import SwiftUI

struct ActiveDestinationComponent: View {
    @State var currentDestination: LocationPlace?
    
    var body: some View {
        
        VStack {
            Spacer()
            
            ZStack{
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.white)
                    .edgesIgnoringSafeArea(.all)
                
                HStack{
                    VStack(alignment: .leading){
                        if let destinationName = currentDestination?.name {
                            Text(destinationName)
                                .font(.system(size: 24))
                                .bold()
                        } else {
                            Text("No destination selected")
                                .font(.system(size: 24))
                                .bold()
                        }
                        
                        Text("5km (10 min)")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        
                    }, label: {
                        ZStack{
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(.red)
                                .frame(width: 50, height: 50)
                            
                            Text("Exit")
                                .foregroundColor(.white)
                        }
                    })
                }
                .padding()
            }
            .frame(height: 100)
        }
    }
}

struct ActiveDestinationComponent_Previews: PreviewProvider {
    static var previews: some View {
//        ContentView()
        ActiveDestinationComponent(currentDestination: LocationPlace(name: "Hello", latitude: 0.3, longitude: 0.3, type: ""))
    }
}
