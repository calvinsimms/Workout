//
//  CreateWorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI
import SwiftData

struct CreateWorkoutView: View {
    @Bindable var workout: Workout
    var isNewWorkout: Bool
    var onSave: ((Workout) -> Void)?
    @Environment(\.dismiss) var dismiss

    @State private var selectedExercises: Set<Exercise>

    init(workout: Bindable<Workout>, isNewWorkout: Bool, onSave: ((Workout) -> Void)? = nil) {
        self._workout = workout
        self.isNewWorkout = isNewWorkout
        self.onSave = onSave

        // Use the actual wrappedValue of Bindable<Workout>
        let exercisesSet = Set(workout.wrappedValue.exercises) // assuming 'exercises' is Set<Exercise>
        _selectedExercises = State(initialValue: exercisesSet)
    }

    var body: some View {
        Form {
            Section("Workout Name") {
                TextField("Title", text: $workout.title)
            }

            Section("Exercises") {
                NavigationLink("Select Exercises") {
                    ExerciseSelectionView(selectedExercises: $selectedExercises)
                }

                ForEach(Array(selectedExercises).sorted(by: { $0.name < $1.name }), id: \.id) { exercise in
                    Text(exercise.name)
                }
            }
        }
        .navigationTitle(isNewWorkout ? "New Workout" : "Edit Workout")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    workout.exercises = Array(selectedExercises).sorted { $0.name < $1.name }
                    onSave?(workout)
                    dismiss()
                }
                .disabled(workout.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}



#Preview {
    // Create an in-memory model container for SwiftData previews
    let workout = Workout(title: "Example", exercises: [
        Exercise(name: "Squats"),
        Exercise(name: "Lunges")
    ])
    CreateWorkoutView(workout: Bindable(workout), isNewWorkout: true)
        .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}

