//
//  Set.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-16.
//

import Foundation
import SwiftData

// MARK: - SetType Enumeration
/// Represents the type of workout set.
/// Each case defines a distinct training style (e.g., lifting weights vs. cardio).
/// Conforms to:
/// - `String` (for readable raw values)
/// - `CaseIterable` (to allow easy iteration through all types)
/// - `Identifiable` (for use in SwiftUI Lists and Pickers)
/// - `Codable` (to support serialization for persistence or export)
enum SetType: String, CaseIterable, Identifiable, Codable {
    case resistance = "Resistance"
    case cardio = "Cardio"
    case bodyweight = "Bodyweight"
    
    /// Required by `Identifiable`, used to uniquely identify each case.
    /// Returns the case’s raw string value as its identifier.
    var id: String { rawValue }
}


/// Describes all possible measurable workout attributes.
enum WorkoutAttribute: String, CaseIterable, Identifiable {
    case weight, reps, rpe, duration, distance, resistance, heartRate
    var id: String { rawValue }

    /// A short display label for UI.
    var label: String {
        switch self {
        case .weight: return "Weight"
        case .reps: return "Reps"
        case .rpe: return "RPE"
        case .duration: return "Duration"
        case .distance: return "Distance"
        case .resistance: return "Resistance"
        case .heartRate: return "Heart Rate"
        }
    }
}

extension SetType {
    /// Returns which attributes apply to this type of exercise.
    var relevantAttributes: [WorkoutAttribute] {
        switch self {
        case .resistance:
            return [.weight, .reps, .rpe]
        case .cardio:
            return [.duration, .distance, .heartRate, .resistance]
        case .bodyweight:
            return [.reps, .rpe]
        }
    }
}


// MARK: - WorkoutSet Model
/// A model representing a single exercise set within a workout.
/// Each `WorkoutSet` stores performance data for one attempt at an exercise.
/// Conforms to `@Model` to integrate with SwiftData’s persistence system.
@Model
final class WorkoutSet: Identifiable {
    
    @Attribute(.unique) var id: UUID
    var type: SetType
    var date: Date

    // Actual values
    var weight: Double?
    var reps: Int?
    var rpe: Double?
    var duration: Double?
    var distance: Double?
    var resistance: Double?
    var heartRate: Int?

    // Target values (optional, new)
    var targetWeight: Double?
    var targetReps: Int?
    var targetRPE: Double?
    var targetDuration: Double?
    var targetDistance: Double?
    var targetResistance: Double?
    var targetHeartRate: Int?

    var order: Int

    @Relationship(inverse: \WorkoutExercise.sets) var workoutExercise: WorkoutExercise?

    init(
        type: SetType,
        date: Date = Date(),
        weight: Double? = nil,
        reps: Int? = nil,
        rpe: Double? = nil,
        duration: Double? = nil,
        distance: Double? = nil,
        resistance: Double? = nil,
        heartRate: Int? = nil,
        order: Int = 0
    ) {
        self.id = UUID()
        self.type = type
        self.date = date
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.duration = duration
        self.distance = distance
        self.resistance = resistance
        self.heartRate = heartRate
        self.order = order

        // Target values start nil
        self.targetWeight = nil
        self.targetReps = nil
        self.targetRPE = nil
        self.targetDuration = nil
        self.targetDistance = nil
        self.targetResistance = nil
        self.targetHeartRate = nil
    }

//    // Convenience function to copy target → actual
//    func applyTargetToActual() {
//        if let t = targetWeight { weight = t }
//        if let t = targetReps { reps = t }
//        if let t = targetRPE { rpe = t }
//        if let t = targetDuration { duration = t }
//        if let t = targetDistance { distance = t }
//        if let t = targetResistance { resistance = t }
//        if let t = targetHeartRate { heartRate = t }
//    }
}
