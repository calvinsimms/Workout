//
//  Calendar.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-11.
//

import Foundation
import SwiftData

// Define a SwiftData model for a single calendar day
@Model
final class CalendarDay: Identifiable {
    // Unique identifier for each CalendarDay instance to
    // ensure no two CalendarDay objects have the same UUID in the database
    @Attribute(.unique) var id: UUID
    
    // The actual date this CalendarDay represents
    var date: Date
    
    // Relationship to associated workouts. One CalendarDay can have multiple workouts
    @Relationship var workoutTemplates: [WorkoutTemplate] = []
    
    // Initializer for creating a new CalendarDay
    // - Parameters:
    //   - id: Optional UUID. Defaults to a new UUID if not provided
    //   - date: The Date that this CalendarDay represents
    //   - workouts: Optional array of Workout objects. Defaults to empty
    init(id: UUID = UUID(), date: Date, workoutTemplates: [WorkoutTemplate] = []) {
        self.id = id
        self.date = date
        self.workoutTemplates = workoutTemplates
    }
}
