//
//  ExerciseSelectionView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//

import SwiftUI
import SwiftData

struct ExerciseSelectionView: View {
    @Binding var selectedExercises: Set<Exercise>
    @Query(sort: \Exercise.name, order: .forward) private var allExercises: [Exercise]

    var body: some View {
        List(allExercises, id: \.id) { exercise in
            HStack {
                Text(exercise.name)
                Spacer()
                if selectedExercises.contains(exercise) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                toggleSelection(for: exercise)
            }
        }
        .navigationTitle("Select Exercises")
    }

    private func toggleSelection(for exercise: Exercise) {
        if selectedExercises.contains(exercise) {
            selectedExercises.remove(exercise)
        } else {
            selectedExercises.insert(exercise)
        }
    }
}



#Preview {
    @Previewable @State var selected: Set<Exercise> = []
    ExerciseSelectionView(selectedExercises: $selected)
        .modelContainer(for: [Exercise.self], inMemory: true)
}

