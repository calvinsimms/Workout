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
    
    var isCompleted: Bool = false
    
    // MARK: - Relationships
    
    /// The parent workout that this record belongs to.
    @Relationship var workoutTemplate: WorkoutTemplate?
    
    @Relationship var workoutEvent: WorkoutEvent?
    
    /// The exercise associated with this record.
    @Relationship var exercise: Exercise
    
    /// A collection of target sets that define detailed set-by-set plans
    /// for this specific exercise within the workout.
    ///
    /// Cascade deletion ensures that when a `WorkoutExercise` is deleted,
    /// all associated `TargetSet` records are automatically removed.
    @Relationship(deleteRule: .cascade) var targetSets: [TargetSet] = []
    
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet] = []
    

    /// Used when attaching to a WorkoutTemplate (e.g., predefined workouts)
    init(
        id: UUID = UUID(),
        notes: String? = nil,
        targetNote: String? = nil,
        targetMode: TargetMode = .simple,
        order: Int = 0,
        workoutTemplate: WorkoutTemplate,
        exercise: Exercise
    ) {
        self.id = id
        self.notes = notes
        self.targetNote = targetNote
        self.targetMode = targetMode
        self.order = order
        self.workoutTemplate = workoutTemplate
        self.workoutEvent = nil
        self.exercise = exercise
        self.targetSets = []
    }

    /// Used when attaching to a WorkoutEvent (e.g., logged sessions)
    init(
        id: UUID = UUID(),
        notes: String? = nil,
        targetNote: String? = nil,
        targetMode: TargetMode = .simple,
        order: Int = 0,
        workoutEvent: WorkoutEvent,
        exercise: Exercise
    ) {
        self.id = id
        self.notes = notes
        self.targetNote = targetNote
        self.targetMode = targetMode
        self.order = order
        self.workoutTemplate = nil
        self.workoutEvent = workoutEvent
        self.exercise = exercise
        self.targetSets = []
    }

    func syncSetCounts() {
        guard sets.count != targetSets.count else { return }

        let maxCount = max(sets.count, targetSets.count)

        // Fill missing target sets
        while targetSets.count < maxCount {
            let newOrder = targetSets.count
            let newTargetSet = TargetSet(order: newOrder, workoutExercise: self)
            targetSets.append(newTargetSet)
        }

        // Fill missing actual sets
        while sets.count < maxCount {
            let newOrder = sets.count
            let newActualSet = WorkoutSet(
                type: exercise.setType,
                date: workoutEvent?.date ?? .now,
                order: newOrder
            )
            newActualSet.workoutExercise = self
            sets.append(newActualSet)
        }
    }

    /// Adds a new actual set to this exercise.
    func addSet() {
        let newOrder = sets.count
        let newSet = WorkoutSet(type: exercise.setType, date: workoutEvent?.date ?? .now, order: newOrder)
        newSet.workoutExercise = self
        sets.append(newSet)

        try? newSet.modelContext?.save()
    }


//    /// Deletes a specific actual set from this exercise and maintains ordering.
//    func deleteSet(_ set: WorkoutSet) {
//        guard let context = set.modelContext else { return }
//
//        // First delete from context
//        context.delete(set)
//        
//        // Then remove from the sets array
//        sets.removeAll { $0.id == set.id }
//
//        // Reorder remaining sets
//        let sortedSets = sets.sorted { $0.order < $1.order }
//        for (index, s) in sortedSets.enumerated() {
//            s.order = index
//        }
//
//        try? context.save()
//    }
    
//    func applyTargetSetToActual(at index: Int) {
//         guard targetSets.indices.contains(index) else { return }
//         let target = targetSets[index]
//
//         // Make sure actual set exists
//         if sets.count <= index {
//             let newSet = WorkoutSet(type: exercise.setType, date: workoutEvent?.date ?? Date(), order: index)
//             newSet.workoutExercise = self
//             sets.append(newSet)
//         }
//
//         let actual = sets[index]
//
//         // Copy values only if target has a non-nil value
//         if let weight = target.weight { actual.weight = weight }
//         if let reps = target.reps { actual.reps = reps }
//         if let rpe = target.rpe { actual.rpe = rpe }
//         if let duration = target.duration { actual.duration = duration }
//         if let distance = target.distance { actual.distance = distance }
//         if let resistance = target.resistance { actual.resistance = resistance }
//         if let heartRate = target.heartRate { actual.heartRate = heartRate }
//     }
    
    // MARK: - Equatable & Hashable
    static func == (lhs: WorkoutExercise, rhs: WorkoutExercise) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


