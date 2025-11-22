//
//  BodyweightEntry.swift
//  Workout
//
//  Created by Calvin Simms on 2025-11-17.
//

import SwiftData
import Foundation

@Model
final class Measurement: Identifiable {
    @Attribute(.unique) var id: UUID
    var type: MeasurementType
    var value: Double
    var date: Date
    
    init(id: UUID = UUID(), type: MeasurementType, value: Double, date: Date) {
        self.id = id
        self.type = type
        self.value = value
        self.date = Calendar.current.startOfDay(for: date)
    }
}

enum MeasurementType: String, Codable, Identifiable, CaseIterable {
    case weight = "Weight"
    case bodyFatPercentage = "Body Fat %"
    case leanMuscleMass = "Lean Muscle Mass"
    case neck = "Neck"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case leftUpperArm = "Left Upper Arm"
    case rightUpperArm = "Right Upper Arm"
    case leftForearm = "Left Forearm"
    case rightForearm = "Right Forearm"
    case waist = "Waist"
    case hips = "Hips"
    case leftThigh = "Left Thigh"
    case rightThigh = "Right Thigh"
    case calves = "Calves"
    
    var id: String { rawValue }
}
