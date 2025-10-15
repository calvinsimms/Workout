//
//  ContentView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-01.
//

import SwiftUI
import SwiftData

// MARK: - ContentView
// The main view of the app that controls tab navigation between different sections:
// - Workouts
// - Calendar
// - Statistics
// - Settings
//
// It also initializes the data environment and seeds default exercises on first launch.
struct ContentView: View {
    
    // MARK: - Environment and Data Queries
    
    // Access to the SwiftData model context (used for inserting, deleting, and saving models)
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all workouts, sorted by their 'order' property (ascending)
    // The @Query property wrapper automatically updates the view when data changes.
    @Query(sort: \Workout.order, order: .forward) private var workouts: [Workout] = []
    
    // Fetch all exercises, sorted alphabetically by name
    @Query(sort: \Exercise.name, order: .forward) private var exercises: [Exercise] = []
    
    
    // MARK: - UI State Variables
    
    // Tracks the currently selected tab ("Workouts", "Calendar", etc.)
    @State private var selectedTab: String = "Workouts"
    
    // Prevents reseeding default exercises multiple times
    @State private var didSeedExercises = false
    
    // Controls visibility of the bottom navigation bar
    // (e.g., hidden when viewing certain detail pages)
    @State private var isNavBarHidden = false
    
    
    // MARK: - Body
    var body: some View {
        ZStack {
            
            // MARK: - Tab Navigation Handling
            // Switches between different views based on the selected tab
            if selectedTab == "Workouts" {
                NavigationStack {
                    WorkoutListView(
                        workouts: workouts,                // Pass current workouts from SwiftData
                        addWorkout: addWorkout,            // Pass function to add new workouts
                        deleteWorkouts: deleteWorkouts,    // Pass function to delete workouts
                        moveWorkouts: moveWorkouts,        // Pass function to reorder workouts
                        isNavBarHidden: $isNavBarHidden    // Bind nav bar visibility to subviews
                    )
                }
            }
            else if selectedTab == "Calendar" {
                NavigationStack {
                    CalendarView()
                }
            }
            else if selectedTab == "Statistics" {
                NavigationStack {
                    StatsView()
                }
            }
            else if selectedTab == "Settings" {
                NavigationStack {
                    SettingsView()
                }
            }
            
            
            // MARK: Custom Navigation Bar
            VStack {
                Spacer()
                
                // Only show nav bar if not hidden
                if !isNavBarHidden {
                    ButtonNavBar(selectedTab: $selectedTab)
                        .padding(.bottom, 30)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        
        // Runs once when the view first appears
        .onAppear {
            seedDefaultExercisesIfNeeded()
        }
    }
    
    
    // MARK: - Data Management Methods
    
    // Adds a new workout to the SwiftData model and assigns an order value.
    // 'order' keeps workouts sorted in a consistent sequence.
    private func addWorkout(_ workout: Workout) {
        withAnimation {
            // Determine new order value (one higher than the current max)
            let newOrder = (workouts.map { $0.order }.max() ?? -1) + 1
            workout.order = newOrder
            
            // Insert into the SwiftData model context
            modelContext.insert(workout)
        }
    }
    
    // Deletes selected workouts based on their indices from the list.
    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(workouts[index])
            }
        }
    }
    
    // Moves workouts in the list and updates their 'order' property
    // so the new order is persisted in the database.
    private func moveWorkouts(offsets: IndexSet, newOffset: Int) {
        withAnimation {
            // Copy and reorder workouts locally
            var reordered = workouts
            reordered.move(fromOffsets: offsets, toOffset: newOffset)
            
            // Update order value for each workout after rearrangement
            for (index, workout) in reordered.enumerated() {
                workout.order = index
            }
        }
    }
    
    
    // MARK: - Seed Default Exercises
    // Populates the Exercise database with a predefined set of common exercises
    // the first time the app runs. This ensures the user starts with data to work with.
    private func seedDefaultExercisesIfNeeded() {
        guard !didSeedExercises else { return } // Already seeded during this session
        guard exercises.isEmpty else { return }  // Skip if user already has data
        
        // List of preloaded exercises
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
        
        // Insert each default exercise into the database
        for exercise in defaultExercises {
            modelContext.insert(exercise)
        }
        
        // Save to persist data
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


