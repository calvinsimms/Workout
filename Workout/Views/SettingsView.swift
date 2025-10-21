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
                                    HStack {
                                        Text("Manage Exercises")

                                        Spacer()
                                    }
                                    
                                }
                                
                                HStack {
                                    Text("Appearance")
                                        
                                    Spacer()
                                }
                            
                                HStack {
                                    Text("Units")
                                        
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Include RPE")
                                        
                                    Spacer()
                                }
                            
                                HStack {
                                    Text("Prevent Screen Sleep")
                                        
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Send Feedback")
                                        
                                    Spacer()
                                }
                            
                                HStack {
                                    Text("Rate in AppStore")
                                        
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Reset Defaults")
                                        
                                    Spacer()
                                }
                               
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
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

