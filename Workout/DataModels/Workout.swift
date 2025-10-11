//
//  Workout.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import Foundation
import SwiftData

enum WorkoutCategory: String, CaseIterable, Identifiable, Codable {
    case weightlifting = "Weightlifting"
    case cardio = "Cardio"
    case other = "Other"

    var id: String { rawValue }
}

@Model
final class Workout: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var order: Int
    @Relationship var exercises: [Exercise] = []
    var category: WorkoutCategory
    
    init(id: UUID = UUID(), title: String, order: Int = 0, exercises: [Exercise] = [], category: WorkoutCategory = .weightlifting) {
        self.id = id
        self.title = title
        self.order = order
        self.exercises = exercises
        self.category = category
    }
}
