//
//  StatsView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

struct StatsView: View {
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                Text("Stats")
                    .font(.largeTitle)
                
                Spacer()
                
            }
        }
    }
}

#Preview {
    StatsView()
}
