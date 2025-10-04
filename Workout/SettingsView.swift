//
//  SettingsView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                Text("Settings")
                    .font(.largeTitle)
                
                Spacer()
                
            }
        }
    }
}

#Preview {
    SettingsView()
}
