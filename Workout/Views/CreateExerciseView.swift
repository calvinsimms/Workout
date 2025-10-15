//
//  CreateExerciseView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI

// MARK: - CreateExerciseView
// A reusable form view for creating or editing an Exercise object.
//
// Supports two modes:
//   - **New Exercise**: Creates a brand-new exercise and inserts it into SwiftData
//   - **Edit Exercise**: Allows editing an existing exercise passed in from elsewhere
//
// The view uses bindings and environment contexts to seamlessly integrate
// with SwiftData and SwiftUI navigation flows.
struct CreateExerciseView: View {
    
    // MARK: - Bound & Environment Properties
    
    // Binding to an Exercise object.
    // Used for both creating new exercises and editing existing ones.
    @Binding var exercise: Exercise
    
    // Determines whether this view is for creating a new exercise
    // or editing an existing one. Controls title and save behavior.
    var isNewExercise: Bool
    
    // Optional closure that runs after the save button is tapped.
    // Useful for triggering refresh actions in parent views.
    var onSave: (() -> Void)?
    
    // Provides the ability to dismiss this sheet or navigation view programmatically.
    @Environment(\.dismiss) var dismiss
    
    // Gives access to SwiftData’s model context for saving or inserting objects.
    @Environment(\.modelContext) private var modelContext
    
    
    // MARK: - Body
    var body: some View {
        Form {
            // Exercise Name Input
            Section(header: Text("Exercise Name")) {
                // Text field bound directly to the Exercise name
                TextField("Name", text: $exercise.name)
            }
        }
        
        // Navigation Bar Title
        // The title changes depending on whether a new exercise is being created
        .navigationTitle(isNewExercise ? "New Exercise" : "Edit Exercise")
        
        // Toolbar Buttons
        .toolbar {
            
            // Confirmation (Save) Button
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // If creating a brand-new exercise, insert into SwiftData context
                    if isNewExercise {
                        modelContext.insert(exercise)
                    }
                    
                    // Run optional onSave closure (used to refresh parent view)
                    onSave?()
                    
                    // Dismiss the current sheet or navigation
                    dismiss()
                }
                // Disable the save button if the name is empty or whitespace-only
                .disabled(exercise.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            // Cancel Button
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    // Simply dismiss the view without saving
                    dismiss()
                }
            }
        }
    }
}


// MARK: - Preview
#Preview {
    // Creates a sample Exercise instance for the preview
    @Previewable @State var sampleExercise = Exercise(name: "Sample Exercise")
    
    // Demonstrates how CreateExerciseView would appear in a NavigationStack
    // when creating a new exercise
    return CreateExerciseView(
        exercise: $sampleExercise, // Binding to a sample exercise
        isNewExercise: true,       // Preview in "create new" mode
        onSave: {
            print("Exercise saved: \(sampleExercise.name)")
        }
    )
}
