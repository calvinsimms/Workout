//
//  Exercise.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//
import Foundation
import SwiftData

@Model
final class Exercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
