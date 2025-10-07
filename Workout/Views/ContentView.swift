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
    @Query(sort: \Exercise.name, order: .forward) private var exercises: [Exercise] = []

    @State private var selectedTab: String = "Workouts"
    @State private var didSeedExercises = false

    var body: some View {
        ZStack {
            if selectedTab == "Workouts" {
                NavigationStack {
                    WorkoutListView(
                        workouts: workouts,
                        addWorkout: addWorkout,
                        deleteWorkouts: deleteWorkouts,
                        moveWorkouts: moveWorkouts
                    )
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
        .onAppear {
            seedDefaultExercisesIfNeeded()
        }
    }

    // MARK: - Add Workout
    private func addWorkout(_ workout: Workout) {
        withAnimation {
            let newOrder = (workouts.map { $0.order }.max() ?? -1) + 1
            workout.order = newOrder
            modelContext.insert(workout)
        }
    }

    // MARK: - Delete Workouts
    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(workouts[index])
            }
        }
    }

    // MARK: - Move Workouts
    private func moveWorkouts(offsets: IndexSet, newOffset: Int) {
        withAnimation {
            var reordered = workouts
            reordered.move(fromOffsets: offsets, toOffset: newOffset)
            for (index, workout) in reordered.enumerated() {
                workout.order = index
            }
        }
    }

    // MARK: - Seed Default Exercises
    private func seedDefaultExercisesIfNeeded() {
        guard !didSeedExercises else { return } // Already seeded
        guard exercises.isEmpty else { return }  // Only seed if empty

        let defaultExercises = [
            Exercise(name: "Bench Press"),
            Exercise(name: "Bench Press - Incline"),
            Exercise(name: "Bench Press - Decline"),
            Exercise(name: "Dumbbell Bench Press"),
            Exercise(name: "Dumbbell Bench Press - Incline"),
            Exercise(name: "Dumbbell Bench Press - Decline"),
            Exercise(name: "Overhead Press"),
            Exercise(name: "Dumbbell Overhead Press"),
            Exercise(name: "Lateral Raise"),
            Exercise(name: "Lateral Raise - Cable"),
            Exercise(name: "Squats"),
            Exercise(name: "Deadlifts"),
            Exercise(name: "Pull-ups")
        ]

        for exercise in defaultExercises {
            modelContext.insert(exercise)
        }

        do {
            try modelContext.save()
            didSeedExercises = true
        } catch {
            print("Failed to seed default exercises: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}


