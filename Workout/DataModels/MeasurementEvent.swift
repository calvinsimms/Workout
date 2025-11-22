//
//  MeasurementEvent.swift
//  Workout
//
//  Created by Calvin Simms on 2025-11-22.
//

import Foundation
import SwiftData

@Model
final class MeasurementEvent: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var order: Int
    @Relationship(deleteRule: .cascade) var measurements: [Measurement]

    init(id: UUID = UUID(), date: Date, order: Int = 0, measurements: [Measurement] = []) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.order = order
        self.measurements = measurements
    }
}
