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
            return [.duration, .distance, .resistance, .heartRate, .rpe]
        case .bodyweight:
            return [.reps, .rpe]   // <- as you requested
        }
    }
}


// MARK: - WorkoutSet Model
/// A model representing a single exercise set within a workout.
/// Each `WorkoutSet` stores performance data for one attempt at an exercise.
/// Conforms to `@Model` to integrate with SwiftData’s persistence system.
@Model
final class WorkoutSet: Identifiable {
    
    // MARK: - Properties
    
    /// A unique identifier for each set, automatically assigned upon creation.
    @Attribute(.unique) var id: UUID
    
    /// The category of this set (e.g., weightlifting, cardio, or bodyweight).
    /// Uses the `SetType` enum for structured typing.
    var type: SetType
    
    /// The date and time when this set was performed.
    /// Defaults to the current date when a new set is created.
    var date: Date
    
    /// The weight used for the set, if applicable (e.g., 135 lbs for squats).
    /// `nil` for cardio or bodyweight exercises that do not involve external load.
    var weight: Double?

    /// The amount of repititions performed
    var reps: Int?
    
    /// The perceived exertion for the set, often rated on a 1–10 RPE scale.
    /// Allows tracking of workout intensity.
    var rpe: Double?
    
    /// The duration of the set (in seconds, minutes, or a custom unit).
    /// Useful for cardio activities like running or cycling.
    var duration: Double?
    
    /// The distance covered during the set (e.g., kilometers or miles).
    /// Typically used for cardio sets (e.g., a 5 km run).
    var distance: Double?
    
    /// The level of resistance for cardio involving machines, such as stationary bikes
    var resistance: Double?
    
    /// User inputs avergae heart rate for the exercise for statistical tracking
    var heartRate: Int?

    /// The parent exercise that this set belongs to.
    /// Defines the inverse side of the relationship to ensure that
    /// when a set is added to an exercise’s `sets` array, this property
    /// automatically references that same exercise (and vice versa).
    /// Declared as optional so sets can be created before being attached
    /// to an exercise instance if needed.
    @Relationship(inverse: \Exercise.sets) var exercise: Exercise?
    
    
    // Reference to the specific workout event this set was performed in
    // Deleting the event cascades deletion of these sets.
    @Relationship var workoutEvent: WorkoutEvent?

    // MARK: - Initializer
    /// Initializes a new `WorkoutSet` with the provided details.
    /// - Parameters:
    ///   - type: The type of set (`SetType` enum).
    ///   - date: The date performed (defaults to now).
    ///   - weight: The weight lifted (optional).
    ///   - reps: The number of repetitions (optional).
    ///   - rpe: The rate of perceived exertion (optional).
    ///   - duration: The duration of the exercise (optional).
    ///   - distance: The distance covered (optional).
    init(
        type: SetType,
        date: Date = Date(),
        weight: Double? = nil,
        reps: Int? = nil,
        rpe: Double? = nil,
        duration: Double? = nil,
        distance: Double? = nil,
        resistance: Double? = nil,
        heartRate: Int? = nil
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
    }
}
