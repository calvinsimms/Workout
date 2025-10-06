//
//  Workout.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import Foundation
import SwiftData

@Model
final class Workout: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var order: Int
    @Relationship var exercises: [Exercise] = []
    
    init(id: UUID = UUID(), title: String, order: Int = 0, exercises: [Exercise] = []) {
        self.id = id
        self.title = title
        self.order = order
        self.exercises = exercises
    }
}
