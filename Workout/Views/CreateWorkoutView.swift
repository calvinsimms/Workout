//
//  CreateWorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI

struct CreateWorkoutView: View {
    @Binding var workout: Workout
    var isNewWorkout: Bool
    var onSave: (() -> Void)?
    @Environment(\.dismiss) var dismiss

    @State private var selectedExercises: Set<Exercise> = []

    var body: some View {
        Form {
            Section("Workout Name") {
                TextField("Title", text: $workout.title)
            }

            Section("Exercises") {
                NavigationLink("Select Exercises") {
                    ExerciseSelectionView(selectedExercises: $selectedExercises)
                }
                // Show selected exercises
                ForEach(Array(selectedExercises), id: \.self) { exercise in
                    Text(exercise.name)
                }
            }
        }
        .navigationTitle(isNewWorkout ? "New Workout" : "Edit Workout")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    workout.exercises = Array(selectedExercises)
                    onSave?()
                    dismiss()
                }
                .disabled(workout.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear {
            selectedExercises = Set(workout.exercises)
        }
    }
}

#Preview {
    CreateWorkoutView(
        workout: .constant(Workout(title: "Example")),
        isNewWorkout: true
    )
}
