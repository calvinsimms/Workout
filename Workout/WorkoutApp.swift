//
//  WorkoutApp.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-01.
//
import SwiftUI
import SwiftData

@main
struct WorkoutApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutTemplate.self,
            Exercise.self,
            WorkoutEvent.self,
            WorkoutExercise.self,
            TargetSet.self,
            WorkoutSet.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("❌ Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
