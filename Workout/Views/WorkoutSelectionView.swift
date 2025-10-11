//
//  WorkoutSelectionView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-11.
//

import SwiftUI

struct WorkoutSelectionView: View {
    var workouts: [Workout]
    var onSelect: (Workout) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(workouts) { workout in
                Button(workout.title) {
                    onSelect(workout)
                    dismiss()
                }
            }
            .navigationTitle("Add Workout")
        }
    }
}

#Preview {
    @Previewable @State var sampleWorkouts: [Workout] = [
        Workout(title: "Leg Day", order: 0),
        Workout(title: "Push Day", order: 1),
        Workout(title: "Run", order: 2)
    ]
    
    WorkoutSelectionView(
        workouts: sampleWorkouts,
        onSelect: { workout in
            print("Selected workout: \(workout.title)")
        }
    )
}

