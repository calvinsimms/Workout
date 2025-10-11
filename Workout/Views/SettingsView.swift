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
                                            .font(.system(.title2, weight: .bold))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    
                                }
                                
                                HStack {
                                    Text("Appearance")
                                        .font(.system(.title2, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                            
                                HStack {
                                    Text("Units")
                                        .font(.system(.title2, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                            
                                HStack {
                                    Text("Prevent Screen Sleep")
                                        .font(.system(.title2, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Send Feedback")
                                        .font(.system(.title2, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                            
                                HStack {
                                    Text("Rate in AppStore")
                                        .font(.system(.title2, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                
                               
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Color("Background"))
                        }
                        
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

