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

    var id: String { rawValue }
}

enum WorkoutAttribute: String, CaseIterable, Identifiable {
    case weight, reps, rpe, duration, distance, resistance, heartRate
    var id: String { rawValue }

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

@Model
final class WorkoutSet: Identifiable {
    
    @Attribute(.unique) var id: UUID
    var type: SetType
    var date: Date

    var isTracked: Bool
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
        isTracked: Bool = true,
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
        self.isTracked = isTracked
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.duration = duration
        self.distance = distance
        self.resistance = resistance
        self.heartRate = heartRate
        self.order = order

        self.targetWeight = nil
        self.targetReps = nil
        self.targetRPE = nil
        self.targetDuration = nil
        self.targetDistance = nil
        self.targetResistance = nil
        self.targetHeartRate = nil
    }
}
