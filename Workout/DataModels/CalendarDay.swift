//
//  Calendar.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-11.
//

import Foundation
import SwiftData

@Model
final class CalendarDay: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    @Relationship var workouts: [Workout] = []
    
    init(id: UUID = UUID(), date: Date, workouts: [Workout] = []) {
        self.id = id
        self.date = date
        self.workouts = workouts
    }
}

