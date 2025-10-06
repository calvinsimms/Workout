//
//  ContentView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-01.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.order, order: .forward) private var workouts: [Workout] = []
    

    @State private var selectedTab: String = "Workouts"

    var body: some View {
        ZStack {
            if selectedTab == "Workouts" {
                NavigationStack {
                    WorkoutsView(workouts: workouts, addWorkout: addWorkout, deleteWorkouts: deleteWorkouts, moveWorkouts: moveWorkouts)
                        
                }
            }
            else if selectedTab == "Calendar" {
                NavigationStack {
                    CalendarView()
                        
                }
            }
            else if selectedTab == "Stats" {
                NavigationStack {
                    StatsView()
                        
                }
            }
            else if selectedTab == "Settings" {
                NavigationStack {
                    SettingsView()
                        
                }
            }

            VStack {
                Spacer()
                
                ButtonNavBar(selectedTab: $selectedTab)
                    .padding(.bottom, 30)
            }
        }

        .edgesIgnoringSafeArea(.bottom)
    }

    private func addWorkout() {
        withAnimation {
            let newOrder = (workouts.map { $0.order }.max() ?? -1) + 1
            let newWorkout = Workout(title: "New Workout", order: newOrder)
            modelContext.insert(newWorkout)
        }
    }

    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(workouts[index])
            }
        }
    }

    private func moveWorkouts(offsets: IndexSet, newOffset: Int) {
        withAnimation {
            var reordered = workouts
            reordered.move(fromOffsets: offsets, toOffset: newOffset)

            for (index, workout) in reordered.enumerated() {
                workout.order = index
            }
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}

