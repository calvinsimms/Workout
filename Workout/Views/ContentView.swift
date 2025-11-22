//
//  ContentView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-01.
//

import SwiftUI
import SwiftData

enum Tab: String {
    case workouts = "Workouts"
    case calendar = "Calendar"
    case statistics = "Statistics"
    case coaching = "Coaching"
    case settings = "Settings"
}

struct ContentView: View {
    
    // MARK: - Environment and Data Queries
    
    // Access to the SwiftData model context (used for inserting, deleting, and saving models)
    @Environment(\.modelContext) private var modelContext
    
    // Tracks the currently selected tab ("Workouts", "Calendar", etc.)
    @State private var selectedTab: Tab = .workouts
    
    // Prevents reseeding default exercises multiple times
    @AppStorage("didSeedExercises") private var didSeedExercises = false

    var body: some View {
        TabView(selection: $selectedTab) {
                    
            // MARK: - Workouts
            NavigationStack {
                WorkoutListView()
            }
            .tabItem {
                Label("Workouts", systemImage: "dumbbell")
            }
            .tag(Tab.workouts)
            
            
            // MARK: - Calendar
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(Tab.calendar)
            
            
            // MARK: - Statistics
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar")
            }
            .tag(Tab.statistics)
            
            // MARK: - Coaching
//            NavigationStack {
//                CoachingView()
//            }
//            .tabItem {
//                Label("Coaching", systemImage: "list.clipboard")
//            }
//            .tag(Tab.coaching)
            
            
            // MARK: - Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(Tab.settings)
        }
        .tint(.black)
        .onAppear {
            seedDefaultExercisesIfNeeded()
        }
    }
    
    // MARK: - Seed Default Exercises
    private func seedDefaultExercisesIfNeeded() {
        // Guard against running if we've already seeded successfully
        guard !didSeedExercises else { return }
        
        do {
            // Fix 2: Use a direct, non-reactive fetch request to count exercises efficiently
            var fetchDescriptor = FetchDescriptor<Exercise>()
            fetchDescriptor.fetchLimit = 1
            let existingExerciseCount = try modelContext.fetch(fetchDescriptor).count
            
            guard existingExerciseCount == 0 else {
                // Data already exists, mark as seeded to prevent future checks if necessary
                didSeedExercises = true
                return
            }
            
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
                Exercise(name: "Bulgarian Split Squat", subCategory: .legs, isBodyweight: false),
                Exercise(name: "Deadlift", subCategory: .legs, isBodyweight: false),
                Exercise(name: "Leg Press", subCategory: .legs, isBodyweight: false),
                Exercise(name: "Lunge", subCategory: .legs, isBodyweight: false),
                Exercise(name: "RDL", subCategory: .legs, isBodyweight: false),
                Exercise(name: "Squat", subCategory: .legs, isBodyweight: false),
                
                // Back
                Exercise(name: "Back Extension", subCategory: .back, isBodyweight: false),
                Exercise(name: "Lat Pulldown", subCategory: .back, isBodyweight: false),
                Exercise(name: "Pull-up", subCategory: .back, isBodyweight: true),
                Exercise(name: "Cable Row - Close Grip", subCategory: .back, isBodyweight: false),
                
                // Biceps
                Exercise(name: "Barbell Curl", subCategory: .biceps, isBodyweight: false),
                Exercise(name: "Dumbbell Curl", subCategory: .biceps, isBodyweight: false),
                
                // Triceps
                Exercise(name: "Tricep Pushdown", subCategory: .triceps, isBodyweight: false),
                Exercise(name: "Overhead Tricep Extension", subCategory: .triceps, isBodyweight: false),
                Exercise(name: "Tricep Rope Extension", subCategory: .triceps, isBodyweight: false),
                
                // Abs
                Exercise(name: "Ab Wheel Weighted", subCategory: .abs, isBodyweight: true),
                Exercise(name: "Crunches", subCategory: .abs, isBodyweight: true),
                Exercise(name: "Plank", subCategory: .abs, isBodyweight: true),
                
                // Cardio
                Exercise(name: "Running", category: .cardio),
                Exercise(name: "Cycling", category: .cardio),
                Exercise(name: "Rowing", category: .cardio)
            ]
            
            
            for exercise in defaultExercises {
                modelContext.insert(exercise)
            }
            
            try modelContext.save()
            didSeedExercises = true
            
        } catch {
            print("❌ Failed to seed default exercises or check existing data: \(error)")
        }
    }
    
}

#Preview {
    ContentView()
}
