//
//  CreateExerciseView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI

struct CreateExerciseView: View {
    @Binding var exercise: Exercise
    var isNewExercise: Bool
    var onSave: (() -> Void)?   // Called when Save is tapped
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Exercise Name")) {
                TextField("Name", text: $exercise.name)
            }
        }
        .navigationTitle(isNewExercise ? "New Exercise" : "Edit Exercise")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave?()
                    dismiss()
                }
                .disabled(exercise.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

#Preview {
    // Temporary state for preview
    @Previewable @State var sampleExercise = Exercise(name: "Sample Exercise")
    
    return CreateExerciseView(
        exercise: $sampleExercise,
        isNewExercise: true,
        onSave: {
            // Preview action (optional)
            print("Exercise saved: \(sampleExercise.name)")
        }
    )
}
