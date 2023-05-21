//
//  DestinationCardView.swift
//  RidingBuddiesTwo
//
//  Created by Rajif Afif on 19/05/23.
//

import SwiftUI

struct DestinationCardView: View {
    var body: some View {
        VStack{
            
            HStack{
                
                VStack(alignment: .leading){
                    Text("Location Name")
                        .font(.system(size: 24))
                        .bold()
                    
                    Text("10 km")
                }
                Spacer()
                
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 1)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct DestinationCardView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationCardView()
    }
}
