//
//  Workout.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import Foundation
import SwiftData

// MARK: - WorkoutCategory Enum

// Enum representing the type or category of a workout.
// This enum provides a way to classify workouts into distinct groups
// Using an enum ensures type safety and prevents using arbitrary strings for categories.
enum WorkoutCategory: String, CaseIterable, Identifiable, Codable {
    case resistance = "RESISTANCE"
    case cardio = "CARDIO"
    case other = "OTHER"

    // Identifiable Conformance
    // Using `rawValue` ensures each enum case has a unique identifier automatically.
    var id: String { rawValue }

    // MARK: - Why These Protocols Are Used
    
    // `CaseIterable`: Automatically provides an `allCases` array containing all enum cases.
    // Useful for creating a Picker, ForEach, or populating a menu with all workout categories:

    // `Identifiable`: Required by SwiftUI's ForEach or List when iterating enums.
    // By using `id = rawValue`, each category can be uniquely identified in UI components.

    // `Codable`: Enables converting enum cases to/from external representations (e.g., JSON, database storage).
    // This makes it easy to save/load `WorkoutCategory` when persisting workouts.
}

// MARK: - Workout Model

// Define a SwiftData model for a Workout
@Model
final class Workout: Identifiable {
    // Unique identifier for each Workout instance to ensure no two workouts share the same UUID
    @Attribute(.unique) var id: UUID
    
    // Title of the workout, e.g., "Leg Day"
    var title: String
    
    // Order number for sorting workouts
    var order: Int
    
    // Relationship to exercises associated with this workout. A workout can contain multiple exercises
    @Relationship var exercises: [Exercise] = []
    
    // Category of the workout, using the WorkoutCategory enum
    var category: WorkoutCategory
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEvent.workout)
    var events: [WorkoutEvent] = []
    
    // Initializer for creating a new Workout
    // - Parameters:
    //   - id: Optional UUID, defaults to a new UUID if not provided
    //   - title: Name/title of the workout
    //   - order: Sorting order, defaults to 0
    //   - exercises: Array of exercises included in the workout, defaults to empty
    //   - category: Category of workout, defaults to `.weightlifting`
    init(
        id: UUID = UUID(),
        title: String,
        order: Int = 0,
        exercises: [Exercise] = [],
        category: WorkoutCategory = .resistance
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.exercises = exercises
        self.category = category
    }
}
