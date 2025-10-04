//
//  Item.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-01.
//

import Foundation
import SwiftData

@Model
final class Item: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var order: Int

    init(title: String, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.order = order
    }
}

