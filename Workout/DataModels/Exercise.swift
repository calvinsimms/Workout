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
//enum subCategory: String, CaseIterable, Identifiable, Codable {
//    
//    // "Resistance Training" subcategories
//    case chest: = "Chest"
//    case back: = "Back"
//    case biceps: = "Biceps"
//    case triceps: = "Triceps"
//    case shoulders: = "Shoulders"
//    case legs: = "Legs"
//    case abs: = "Abs"
//    case otherWeightlifting: = "Other"
//    
//    // "Cardio" subcategories
//    case running: = "Running"
//    case cycling: = "Cycling"
//    case swimming: = "Swimming"
//    case otherCardio: = "Other"
//
//    // "Other" subcategories???
//
//    var id: String { rawValue }
//    
//}

// Define a SwiftData model for a single Exercise
@Model
final class Exercise: Identifiable, Hashable {
    // Unique identifier for each Exercise instance to
    // ensure no two Exercise objects have the same UUID in the database
    @Attribute(.unique) var id: UUID
    
    // Name of the exercise, must also be unique to prevent
    // duplicate exercises with the same name in the data store
    @Attribute(.unique) var name: String
    
    // Initializer for creating a new Exercise
    // - Parameters:
    //   - id: Optional UUID. Defaults to a new UUID if not provided
    //   - name: Name of the exercise
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
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
