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
    
    // Let's "Add ____ Workout" in WorkoutListView pass the category to this view 
    var workoutCategory: WorkoutCategory
    
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
    init(workout: Workout, isNewWorkout: Bool, isNavBarHidden: Binding<Bool>, workoutCategory: WorkoutCategory = .resistance, onSave: ((Workout) -> Void)? = nil) {
         self._workout = Bindable(workout)
         self.isNewWorkout = isNewWorkout
         self._isNavBarHidden = isNavBarHidden
         self.workoutCategory = workoutCategory
         self.onSave = onSave
        _selectedExercises = State(initialValue: Set(workout.workoutExercises.map { $0.exercise }))
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
                .disabled(!selectedExercises.isEmpty) // disable if any exercises are added
                

                   if !selectedExercises.isEmpty {
                       HStack {
                           Spacer ()
                           Text("Category locked - remove exercises to change")
                               .font(.footnote)
                               .foregroundColor(.gray)
                           Spacer()
                       }
                           
                   }
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
        .scrollContentBackground(.hidden) // hides default form background
        .background(Color("Background")) 
        // Title changes depending on whether we’re creating or editing.
        .navigationTitle(isNewWorkout ? "New Workout" : "Edit Workout")
        
        // Toolbar Configuration
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // Clear old workout exercises
                    workout.workoutExercises.removeAll()
                    
                    // Create a WorkoutExercise for each selected Exercise
                    let newWorkoutExercises = Array(selectedExercises)
                        .sorted(by: { $0.name < $1.name })
                        .enumerated()
                        .map { index, exercise in
                            WorkoutExercise(
                                notes: nil,
                                targetNote: nil,
                                order: index,
                                workout: workout,
                                exercise: exercise
                            )
                        }
                    
                    // Assign the new ones
                    workout.workoutExercises = newWorkoutExercises
                    
                    // Trigger save callback
                    onSave?(workout)
                    dismiss()
                }
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

    let workout = Workout(title: "Example")

    CreateWorkoutView(
        workout: workout,          
        isNewWorkout: true,
        isNavBarHidden: $isNavBarHidden
    )
}
