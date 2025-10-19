//
//  CreateWorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI
import SwiftData

// A view used for creating or editing a Workout.
// It allows users to specify a workout title, category, and select exercises.
struct CreateWorkoutView: View {
    // MARK: - Properties
    
    // The workout being created or edited.
    // `@Bindable` allows SwiftData to observe changes and automatically update the model.
    @Bindable var workout: Workout
    
    // Whether this view is creating a new workout or editing an existing one.
    var isNewWorkout: Bool
    
    /// Binding to control visibility of the parent navigation bar.
    @Binding var isNavBarHidden: Bool
    
    // A callback closure executed when the user taps "Save".
    // Useful for parent views to handle the saved workout.
    var onSave: ((Workout) -> Void)?
    
    // Dismisses the current view when called.
    @Environment(\.dismiss) var dismiss
    
    // Tracks the currently selected exercises for this workout.
    // A `Set` is used to prevent duplicates.
    @State private var selectedExercises: Set<Exercise>
    
    // MARK: - Initializer
    
    // Custom initializer that sets up binding and initial state.
    // - Parameters:
    //   - workout: A bindable instance of a Workout model.
    //   - isNewWorkout: Indicates whether this is a new workout being created.
    //   - isNavBarHidden: A binding that controls the visibility of the parent’s navigation bar.
    //                     When this view appears, it sets the binding to `true` to hide the bar,
    //                     and resets it to `false` when dismissed, ensuring consistent UI behavior.
    //   - onSave: Optional closure to handle the save action.
    init(workout: Workout, isNewWorkout: Bool, isNavBarHidden: Binding<Bool>, onSave: ((Workout) -> Void)? = nil) {
         self._workout = Bindable(workout)
         self.isNewWorkout = isNewWorkout
         self._isNavBarHidden = isNavBarHidden
         self.onSave = onSave
         _selectedExercises = State(initialValue: Set(workout.exercises))
     }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            Section("Workout Name") {
                // Text field for entering or editing the workout’s title.
                TextField("Title", text: $workout.title)
            }
            
            // Category Section
            Section(header: Text("Category")) {
                // Picker for selecting a workout category (e.g., Strength, Cardio).
                Picker("Category", selection: $workout.category) {
                    ForEach(WorkoutCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Exercises Section
            Section("Exercises") {
                // Navigation link to a separate screen for selecting exercises.
                NavigationLink("Select Exercises") {
                    ExerciseSelectionView(selectedExercises: $selectedExercises,
                                          workoutCategory: workout.category,
                                          isNavBarHidden: $isNavBarHidden)
                }

                // Display the list of selected exercises.
                // Sorted alphabetically by exercise name.
                ForEach(Array(selectedExercises).sorted(by: { $0.name < $1.name }), id: \.id) { exercise in
                    Text(exercise.name)
                }
            }
        }
        // Title changes depending on whether we’re creating or editing.
        .navigationTitle(isNewWorkout ? "New Workout" : "Edit Workout")
        
        // Toolbar Configuration
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // Update the workout model with the current selection.
                    workout.exercises = Array(selectedExercises).sorted { $0.name < $1.name }
                    
                    // Trigger the save callback, if provided.
                    onSave?(workout)
                    
                    // Dismiss the view to return to the previous screen.
                    dismiss()
                }
                // Disable save if the title field is empty or whitespace-only.
                .disabled(workout.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            // Slight delay ensures nav push begins before hiding bar
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarHidden = true
                }
            }
        }
        .onDisappear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isNavBarHidden = false
            }
        }
    }
}

#Preview {
    @Previewable @State var isNavBarHidden = false

    let workout = Workout(
        title: "Example",
        exercises: [
            Exercise(name: "Squats"),
            Exercise(name: "Lunges")
        ]
    )

    CreateWorkoutView(
        workout: workout,          
        isNewWorkout: true,
        isNavBarHidden: $isNavBarHidden
    )
    .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}
