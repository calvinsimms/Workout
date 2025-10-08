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
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .padding(.top, 40)

                    Divider()
                    
                    
                    NavigationStack {
                        List {
                            Section {
                                NavigationLink(destination: ExercisesView()) {
                                    HStack {
                                        Text("Manage Exercises")
                                            .font(.system(.title, weight: .bold))
                                            .foregroundColor(.black)
                                        Spacer()
                           
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                            }
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

