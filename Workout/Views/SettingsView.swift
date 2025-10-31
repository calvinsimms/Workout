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
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
            
                    
                    HStack {
                        Spacer()
                        Text("Settings")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    .padding(.top, 10)


                    Divider()
                    
                    
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
                        .scrollContentBackground(.hidden)
                        .background(Color("Background"))
                    
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}

