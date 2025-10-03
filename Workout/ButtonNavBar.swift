//
//  ButtonNavBar.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-03.
//

import SwiftUI

struct ButtonNavBar: View {
    var body: some View {
        
        ZStack {
            HStack{
                Button("Home", systemImage: "house.fill") {
                    
                }
                .padding(10)
                .padding(.leading, 10)
                
                Button("Calendar", systemImage: "calendar") {
                    
                }
                .padding(10)
                
                Button("Stats", systemImage: "chart.xyaxis.line") {
                    
                }
                .padding(10)
                
                Button("Settings", systemImage: "gearshape.fill") {
                    
                }
                .padding(10)
                .padding(.trailing, 10)
            }
    
            
            .background(
                ZStack {
                    Color.black.opacity(0.1)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                }
            )

            
            .font(.largeTitle)
            .labelStyle(.iconOnly)
            .tint(.black)
            
        }
    }
}

#Preview {
    ButtonNavBar()
}
