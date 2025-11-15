//
//  WorkoutEvent.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-22.
//

import Foundation
import SwiftData

// MARK: - WorkoutEvent Model

// Represents a scheduled instance of a workout on a specific date.
// This model links a Workout template (e.g., "Push Day") to a calendar date (e.g., October 22, 2025),
// allowing users to plan when each workout will occur.
//
// Unlike the Workout model, which defines the structure of a workout (its name, category, and exercises),
// WorkoutEvent represents the *occurrence* of that workout — i.e., when it is performed.
// This distinction enables multiple scheduled sessions for the same workout without data duplication.

@Model
final class WorkoutEvent: Identifiable {
    
    // MARK: - Core Properties
    
    // Unique identifier for this specific scheduled workout event.
    // The `.unique` attribute ensures no two events share the same UUID,
    // which is essential for reliable persistence and SwiftUI List identification.
    @Attribute(.unique) var id: UUID
    
    var title: String?
    
    var displayTitle: String {
        title ?? workoutTemplate?.title ?? "Untitled Workout"
    }
    
    // The calendar date when this workout occurs.
    var date: Date
    
    // Optional property representing the time of day when the workout starts.
    // Example: 7:00 AM — can be used for time-based reminders or scheduling in future updates.
    var startTime: Date?
    
    // Optional text field allowing users to add personal notes about this workout session.
    var notes: String?
    
    var order: Int
    
    
    // Optional link to a reusable workout template (can be nil for one-off sessions)
    @Relationship var workoutTemplate: WorkoutTemplate?
    
    // All sets performed in this event
    // Cascade deletion ensures that when an event is deleted,
    // all logged sets for that event are removed automatically.
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workoutEvent)
    var workoutExercises: [WorkoutExercise] = []
    
    // MARK: - Initializer
    
    // Custom initializer for creating a new scheduled workout event.
    //
    // - Parameters:
    //   - id: Unique identifier (defaults to a new UUID if not provided)
    //   - date: The specific day the workout is planned for
    //   - workout: The linked Workout object defining the exercise routine
    //   - startTime: (Optional) The time the workout begins
    //   - notes: (Optional) Additional notes or reminders for the session
    init(
        id: UUID = UUID(),
        date: Date,
        title: String? = nil,
        workoutTemplate: WorkoutTemplate? = nil,
        startTime: Date? = nil,
        notes: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.workoutTemplate = workoutTemplate
        self.startTime = startTime
        self.notes = notes
        self.order = order
    }
}
