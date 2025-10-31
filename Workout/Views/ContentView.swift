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
    
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - Workouts
            NavigationStack {
                WorkoutListView(
                    workouts: workouts,
                    addWorkout: addWorkout,
                    deleteWorkouts: deleteWorkouts,
                    moveWorkouts: moveWorkouts,
                    isNavBarHidden: $isNavBarHidden
                )
            }
            .tabItem {
                Label("Workouts", systemImage: "list.bullet.rectangle")
            }
            .tag("Workouts")
            
            
            // MARK: - Calendar
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag("Calendar")
            
            
            // MARK: - Statistics
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.xyaxis.line")
            }
            .tag("Statistics")
            
            
            // MARK: - Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag("Settings")
        }
        .tint(.black)
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
    // the first time the app runs. Each exercise is assigned a subcategory
    // to enable filtering and organization by muscle group.
    private func seedDefaultExercisesIfNeeded() {
        guard !didSeedExercises else { return } // Already seeded during this session
        guard exercises.isEmpty else { return }  // Skip if user already has data
        
        // MARK: Default Exercises
        // A curated list of common resistance exercises with their respective subcategories.
        // These will appear automatically grouped under their muscle group in the app.
        let defaultExercises: [Exercise] = [
            // Chest
            Exercise(name: "Bench Press", subCategory: .chest, isBodyweight: false),
            Exercise(name: "Bench Press - Incline", subCategory: .chest, isBodyweight: false),
            Exercise(name: "Bench Press - Decline", subCategory: .chest, isBodyweight: false),
            Exercise(name: "Dumbbell Bench Press", subCategory: .chest, isBodyweight: false),
            Exercise(name: "Dumbbell Bench Press - Incline", subCategory: .chest, isBodyweight: false),
            Exercise(name: "Dumbbell Bench Press - Decline", subCategory: .chest, isBodyweight: false),

            // Shoulders
            Exercise(name: "Overhead Press", subCategory: .shoulders, isBodyweight: false),
            Exercise(name: "Dumbbell Overhead Press", subCategory: .shoulders, isBodyweight: false),
            Exercise(name: "Lateral Raise", subCategory: .shoulders, isBodyweight: false),
            Exercise(name: "Lateral Raise - Cable", subCategory: .shoulders, isBodyweight: false),

            // Legs
            Exercise(name: "Squats", subCategory: .legs, isBodyweight: false),
            Exercise(name: "Deadlifts", subCategory: .legs, isBodyweight: false),

            // Back
            Exercise(name: "Pull-ups", subCategory: .back, isBodyweight: true), 
            Exercise(name: "Lat Pulldown", subCategory: .back, isBodyweight: false),
            Exercise(name: "Seated Row", subCategory: .back, isBodyweight: false),

            // Biceps
            Exercise(name: "Barbell Curl", subCategory: .biceps, isBodyweight: false),
            Exercise(name: "Dumbbell Curl", subCategory: .biceps, isBodyweight: false),

            // Triceps
            Exercise(name: "Tricep Pushdown", subCategory: .triceps, isBodyweight: false),
            Exercise(name: "Overhead Tricep Extension", subCategory: .triceps, isBodyweight: false),

            // Abs
            Exercise(name: "Crunches", subCategory: .abs, isBodyweight: true), // ✅ bodyweight
            Exercise(name: "Plank", subCategory: .abs, isBodyweight: true),     // ✅ bodyweight

            // Cardio
            Exercise(name: "Running", category: .cardio),
            Exercise(name: "Cycling", category: .cardio),
            Exercise(name: "Rowing", category: .cardio)
        ]

        
        // MARK: Insert & Save
        // Insert each default exercise into the database
        for exercise in defaultExercises {
            modelContext.insert(exercise)
        }
        
        // Save to persist data in SwiftData
        do {
            try modelContext.save()
            didSeedExercises = true
        } catch {
            print("❌ Failed to seed default exercises: \(error)")
        }
    }
}


#Preview {
    ContentView()
}
