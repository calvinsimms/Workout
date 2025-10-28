//
//  WorkoutExercise.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-27.
//

import Foundation
import SwiftData

// MARK: - Target Mode Enumeration
/// Determines whether the exercise uses simple or advanced target tracking.
enum TargetMode: String, Codable, CaseIterable, Identifiable {
    case simple = "Simple"
    case advanced = "Advanced"

    var id: String { rawValue }
}

/// A model that represents the link between a `Workout` and an `Exercise`.
///
/// This class defines a join entity for a many-to-many relationship,
/// allowing a single workout to include multiple exercises, and a single
/// exercise to appear in multiple workouts.
///
/// Each `WorkoutExercise` instance may also include metadata such as
/// notes, target notes, target sets, and ordering information.
@Model
final class WorkoutExercise: Identifiable, Hashable {
    
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    
    // MARK: - Notes
    /// Optional user notes for this specific workout-exercise pairing.
    var notes: String?
    
    /// Optional target notes — for example, goals or instructions
    /// specific to this exercise within the workout.
    var targetNote: String?

    // MARK: - Target Mode
    /// Determines whether this exercise uses simple text-based targets or
    /// advanced structured target sets.
    var targetMode: TargetMode = TargetMode.simple
    
    // MARK: - Ordering
    var order: Int
    
    // MARK: - Relationships
    
    /// The parent workout that this record belongs to.
    @Relationship var workout: Workout?
    
    /// The exercise associated with this record.
    @Relationship var exercise: Exercise
    
    /// A collection of target sets that define detailed set-by-set plans
    /// for this specific exercise within the workout.
    ///
    /// Cascade deletion ensures that when a `WorkoutExercise` is deleted,
    /// all associated `TargetSet` records are automatically removed.
    @Relationship(deleteRule: .cascade) var targetSets: [TargetSet] = []
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        notes: String? = nil,
        targetNote: String? = nil,
        targetMode: TargetMode = .simple,
        order: Int = 0,
        workout: Workout,
        exercise: Exercise
    ) {
        self.id = id
        self.notes = notes
        self.targetNote = targetNote
        self.targetMode = targetMode
        self.order = order
        self.workout = workout
        self.exercise = exercise
        self.targetSets = []
    }
    
    // MARK: - Equatable & Hashable
    static func == (lhs: WorkoutExercise, rhs: WorkoutExercise) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


