//
//  DestinationCardView.swift
//  RidingBuddiesTwo
//
//  Created by Rajif Afif on 19/05/23.
//

import SwiftUI

struct DestinationCardView: View {
    var locationPlace: LocationPlace
    
    var body: some View {
        VStack{
            
            HStack{
                
                VStack(alignment: .leading){
                    Text(locationPlace.name)
                        .font(.system(size: 18))
                        .bold()
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                        .foregroundColor(.black)
                    
                    Text("\(distanceDoubleToString(distance: locationPlace.distanceInKm)) km (\(estimateInMinutes(distanceInKm: locationPlace.distanceInKm)) min)")
                        .foregroundColor(.black)
                }
                Spacer()
                
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 1)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

struct DestinationCardView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationCardView(locationPlace: LocationPlace(name: "Hello", latitude: 0.3, longitude: 0.3, type: "", distanceInKm: 0.0))
    }
}
