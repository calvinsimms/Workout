//
//  Exercise.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import Foundation
import SwiftData


// MARK: - defining subcategories for exercises
// these will fall into overall categories (resistance , cardio, and other)
enum SubCategory: String, CaseIterable, Identifiable, Codable {
    
    // "Resistance Training" subcategories
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case shoulders = "Shoulders"
    case abs = "Abs"
    case otherResistance = "Other"
    
    /// Provides a unique identifier for each subcategory case based on its raw string value.
    /// This allows the enum to conform to the `Identifiable` protocol, which is required
    /// for use in SwiftUI views such as `ForEach` and `List`.
    var id: String { rawValue }

    /// Indicates which main workout category (e.g., Resistance, Cardio, or Other)
    /// this subcategory belongs to. Since all defined subcategories here represent
    /// types of resistance exercises, this property always returns `.resistance`.
    /// This helps determine which subcategories to display when filtering exercises
    /// by workout type.
    var parentCategory: WorkoutCategory {
        return .resistance
    }

    
}

// Define a SwiftData model for a single Exercise
@Model
final class Exercise: Identifiable, Hashable {
    
    /// Unique identifier for each Exercise instance to
    /// ensure no two Exercise objects have the same UUID in the database.
    @Attribute(.unique) var id: UUID
    
    /// Name of the exercise, must also be unique to prevent
    /// duplicate exercises with the same name in the data store.
    @Attribute(.unique) var name: String
    
    /// Represents a more specific classification for resistance exercises
    /// (e.g., Chest, Legs, Back, etc.). Cardio and "Other" exercises may not
    /// require subcategories, so this property is optional.
    var subCategory: SubCategory?
    
    /// Stores the main workout category (Resistance, Cardio, or Other).
    /// Unlike `subCategory`, this property is required for all exercises.
    /// It ensures that cardio exercises can belong directly to the cardio
    /// category without needing a subcategory.
    var category: WorkoutCategory
    
    /// Indicates whether this resistance exercise is performed using bodyweight only.
    /// Applies only to `.resistance` category exercises.
    var isBodyweight: Bool = false
    
    /// A collection of all workout sets that belong to this exercise.
    ///
    /// Represents a one-to-many relationship where a single exercise
    /// can have multiple associated `WorkoutSet` records.
    ///
    /// Applying `.cascade` as the delete rule ensures that when an
    /// exercise is deleted, all of its related sets are automatically
    /// removed from the data store as well. This prevents orphaned
    /// performance data from remaining after an exercise is deleted,
    /// keeping the database clean and consistent.
    ///
    /// SwiftData automatically synchronizes this relationship with
    /// each set’s `exercise` property, so adding or removing a set
    /// from this array will automatically update the corresponding
    /// reference in `WorkoutSet`.
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet] = []
    
    /// A collection of all `WorkoutExercise` instances linked to this exercise.
    ///
    /// Represents another one-to-many relationship where a single exercise
    /// can be associated with multiple `WorkoutExercise` records.
    ///
    /// The `.cascade` delete rule ensures that when this exercise is deleted,
    /// all related `WorkoutExercise` objects are automatically removed,
    /// preventing dangling references in the data model.
    ///
    /// The `inverse` parameter (`\WorkoutExercise.exercise`) defines the
    /// bidirectional relationship between `Exercise` and `WorkoutExercise`.
    /// This allows SwiftData to automatically keep both sides of the
    /// relationship synchronized — when a `WorkoutExercise` is added or
    /// removed, the corresponding `exercise` reference in that object is
    /// updated accordingly.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise] = []

    @Attribute var isFavorite: Bool = false

    
    init(
        id: UUID = UUID(),
        name: String,
        category: WorkoutCategory = .other,
        subCategory: SubCategory? = nil,
        isBodyweight: Bool = false,
        isFavorite: Bool = false

    ) {
        self.id = id
        self.name = name
        self.subCategory = subCategory
        self.isBodyweight = isBodyweight
        self.category = subCategory?.parentCategory ?? category
        self.isFavorite = isFavorite

    }
    
    // MARK: - Derived Properties
    
    var canBeFavorited: Bool {
         category == .resistance
     }

    /// Determines which `SetType` applies to this exercise.
    /// Used to decide which attributes or inputs are relevant when planning or logging sets.
    var setType: SetType {
        switch category {
        case .cardio:
            return .cardio
        case .resistance:
            return isBodyweight ? .bodyweight : .resistance
        case .other:
            // Treat "other" as bodyweight for now (e.g., stretching or mobility)
            return .bodyweight
        }
    }

    
    // MARK: - Hashable & Equatable Conformance
    
    // Equatable conformance: Exercises are considered equal if their IDs match
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
    
    // Hashable conformance: Use the unique ID to compute the hash
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    // MARK: - Why Hashable is Needed
       /*
        Hashable allows Exercise objects to be stored in collections that require uniqueness or fast lookup,
        such as Sets or as keys in Dictionaries. Without Hashable, you couldn't do things like:
        
        1. Store a set of exercises to ensure no duplicates:
           var exerciseSet: Set<Exercise> = []
           exerciseSet.insert(Exercise(name: "Squat"))
        
        2. Use Exercise as a key in a Dictionary:
           var exerciseData: [Exercise: Int] = [:]
           exerciseData[Exercise(name: "Push-up")] = 10
        
        3. SwiftUI's ForEach can also benefit from Hashable when using dynamic data structures.
        
        By making the hash based on the unique `id`, we ensure that each Exercise is uniquely identifiable
        even if two exercises have the same name.
       */
}
