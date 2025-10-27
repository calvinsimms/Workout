//
//  WorkoutExercise.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-27.
//

import Foundation
import SwiftData

/// A model that represents the link between a `Workout` and an `Exercise`.
///
/// This class defines a join entity for a many-to-many relationship,
/// allowing a single workout to include multiple exercises, and a single
/// exercise to appear in multiple workouts.
///
/// Each `WorkoutExercise` instance may also include metadata such as
/// notes, target notes, and ordering information.
@Model
final class WorkoutExercise: Identifiable, Hashable {
    
    /// A unique identifier for this `WorkoutExercise` record.
    /// The `.unique` attribute ensures no duplicate IDs are stored.
    @Attribute(.unique) var id: UUID
    
    /// Optional user notes for this specific workout-exercise pairing.
    var notes: String?
    
    /// Optional target notes — for example, goals or instructions
    /// specific to this exercise within the workout.
    var targetNote: String?
    
    /// The order of this exercise within the workout sequence.
    /// Used for sorting exercises in a given workout.
    var order: Int
    
    /// The parent workout that this record belongs to.
    ///
    /// This defines the “many” side of a relationship where one workout
    /// can have multiple `WorkoutExercise` entries.
    @Relationship var workout: Workout?
    
    /// The exercise associated with this record.
    ///
    /// This defines the “many” side of a relationship where one exercise
    /// can appear in multiple workouts.
    /// The inverse relationship is defined in `Exercise` as
    /// `@Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.exercise)`.
    @Relationship var exercise: Exercise
    
    /// Initializes a new `WorkoutExercise` with optional notes and a defined order.
    init(id: UUID = UUID(),
         notes: String? = nil,
         targetNote: String? = nil,
         order: Int = 0,
         workout: Workout,
         exercise: Exercise) {
        self.id = id
        self.notes = notes
        self.targetNote = targetNote
        self.order = order
        self.workout = workout
        self.exercise = exercise
    }
    
    /// Equatable conformance — two `WorkoutExercise` objects are considered
    /// equal if they share the same unique `id`.
    static func == (lhs: WorkoutExercise, rhs: WorkoutExercise) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashable conformance — combines the unique `id` for use in sets or dictionaries.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

