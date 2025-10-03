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
                Button(action: { hapticClunk()
                      }) { Label("Home", systemImage: "house.fill") }
                .padding(10)
                .padding(.leading, 10)
                
                Button(action: { hapticClunk()
                      }) { Label("Calendar", systemImage: "calendar") }
                    .padding(10)
                
                Button(action: { hapticClunk()
                      }) { Label("Stats", systemImage: "chart.xyaxis.line") }
                    .padding(10)
                
                Button(action: { hapticClunk()
                      }) { Label("Settings", systemImage: "gearshape.fill") }
                    .padding(10)
                    .padding(.trailing, 10)
            }
            .background(
                   RoundedRectangle(cornerRadius: 30)
                    .fill(Color("Button").opacity(0.9))
               )
            .font(.largeTitle)
            .labelStyle(.iconOnly)
            .tint(.black)
            .shadow(radius: 3)
        }
    }
    
    private func hapticClunk() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    ButtonNavBar()
}
