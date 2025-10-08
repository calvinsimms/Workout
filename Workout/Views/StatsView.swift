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
            
            VStack(spacing: 0) {
        
                
                HStack {
                    Text("Statistics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .padding(.top, 40)

                Divider()
                
                Spacer()
            }
        }
    }
}

#Preview {
    StatsView()
}
