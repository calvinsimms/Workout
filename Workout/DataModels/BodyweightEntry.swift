//
//  BodyweightEntry.swift
//  Workout
//
//  Created by Calvin Simms on 2025-11-17.
//

import SwiftData
import Foundation

@Model
final class BodyweightEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weight: Double?

    init(id: UUID = UUID(), date: Date, weight: Double? = nil) {
        self.id = id
        self.date = date
        self.weight = weight
    }
}
