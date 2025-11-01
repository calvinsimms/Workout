//
//  SettingsView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
                    
            List {
                Section {
                    NavigationLink(destination: ExercisesView()) {
                        Text("Manage Exercises")
                    }

                    Text("Appearance")

                    Text("Units")
                        
                    Text("Include RPE")
                    
                    // Will include 1RM, Wilks, DOTS, etc.
                    Text("Calculations")
            
                    Text("Prevent Screen Sleep")

                    Text("Send Feedback")

                    Text("Rate in AppStore")

                    Text("Reset Defaults")
                            
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color("Background"))
            }
            .font(.system(.title3, weight: .semibold))
            .foregroundColor(.black)
            .tint(.black)
            .listStyle(.plain)
            .background(Color("Background"))
            .navigationTitle("Settings ")
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Settings")
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .foregroundColor(.black)
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)

        }

    }
}

#Preview {
    SettingsView()
}

