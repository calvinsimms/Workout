//
//  ExerciseSelectionView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//

import SwiftUI
import SwiftData

// A view that allows the user to select exercises from a list.
// Users can also create new exercises via a sheet modal.
struct ExerciseSelectionView: View {
    // A binding to the parent’s set of selected exercises.
    // When a user selects/deselects exercises here, it updates the parent view.
    @Binding var selectedExercises: Set<Exercise>
    
    // A SwiftData query that fetches all exercises from the database,
    // sorted alphabetically by name in ascending order.
    @Query(sort: \Exercise.name, order: .forward) private var allExercises: [Exercise]
    
    // Access to the model context (used for inserting new exercises).
    @Environment(\.modelContext) private var modelContext
    
    // Dismiss environment action to close the current view.
    @Environment(\.dismiss) private var dismiss
    
    // Controls presentation of the create-exercise sheet.
    // When true, the "CreateExerciseView" modal is presented to the user.
    @State private var showingCreateExercise = false

    // A temporary exercise object used for creating new exercises.
    // This instance is passed into the create sheet, then saved or discarded
    // depending on user action.
    @State private var newExercise = Exercise(name: "")
    
    // Tracks which resistance subcategories are currently expanded in the list.
    // Each `SubCategory` in this set corresponds to a DisclosureGroup that is open.
    // Used to control the expand/collapse state of each subcategory section dynamically,
    // so that the UI remembers which groups the user has expanded while browsing exercises.
    @State private var expandedGroups: Set<SubCategory> = []
    
    // For animating the Confirm button when the page loads
    @State private var showConfirmButton = false

    // The workout category that determines which exercises should be shown.
    // Passed from the parent view (e.g., CreateWorkoutView) so that only
    // exercises matching this type (Resistance, Cardio, or Other) appear in the list.
    var workoutCategory: WorkoutCategory

    // Computed property that filters all stored exercises based on the selected
    // workout category. This ensures the user only sees relevant exercises
    // for the type of workout they are currently building.
    private var filteredExercises: [Exercise] {
        allExercises.filter { $0.category == workoutCategory }
    }
    var body: some View {
        List {
            if workoutCategory == .resistance {
                ForEach(SubCategory.allCases) { sub in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedGroups.contains(sub) },
                            set: { isExpanded in
                                withAnimation {
                                   if isExpanded {
                                       expandedGroups.insert(sub)
                                   } else {
                                       expandedGroups.remove(sub)
                                   }
                               }
                            }
                        )
                    ) {
                        ForEach(
                            allExercises.filter { $0.subCategory == sub },
                            id: \.id
                        ) { exercise in
                            exerciseRow(exercise)
                        }
                    } label: {
                        Text(sub.rawValue)
                    }
                    .listRowBackground(Color("Background"))
                }
            } else {
                ForEach(
                    allExercises.filter { $0.category == workoutCategory },
                    id: \.id
                ) { exercise in
                    exerciseRow(exercise)
                }
                .listRowBackground(Color("Background"))
            }
        }
        .listStyle(GroupedListStyle())
        .fontWeight(.bold)
        .scrollContentBackground(.hidden)
        .background(Color("Background"))

        .navigationTitle("Select Exercises")
        .toolbar {
                      
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    newExercise = Exercise(name: "", category: workoutCategory)
                    showingCreateExercise = true
                }) {
                    Text("New")
                }
            }
            
//            ToolbarItem(placement: .bottomBar) {
//                Button(action: {
//                    selectedExercises = Set(selectedExercises)
//                    dismiss()
//                }) {
//                    Text("Done")
//                        .font(.headline)
//                        .fontWeight(.bold)
//                        .foregroundColor(.black)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 10)
//                }
//            }
        }
        
        // Sheet for Creating a New Exercise
        .sheet(isPresented: $showingCreateExercise) {
            NavigationStack {
                CreateExerciseView(
                    exercise: $newExercise,
                    isNewExercise: true,
                    defaultCategory: workoutCategory,
                    onSave: {
                        // Save new exercise to model context
                        modelContext.insert(newExercise)
                        // Close the sheet
                        showingCreateExercise = false
                    }
                )
            }
        }
    }
    
    // Helper: Toggle Selection
    // Adds or removes an exercise from the selected set.
    private func toggleSelection(for exercise: Exercise) {
        if selectedExercises.contains(exercise) {
            selectedExercises.remove(exercise)
        } else {
            selectedExercises.insert(exercise)
        }
    }
    
    /// A reusable view that displays a single exercise row in the exercise list.
    /// Each row shows:
    /// - the exercise name on the left,
    /// - a filled circle indicator on the right if it's currently selected,
    /// and supports tap-to-select / deselect interaction.
    ///
    /// - Parameter exercise: The `Exercise` model to display in this row.
    /// - Returns: A view representing the row.
    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack {
            Text(exercise.name)
            
            Spacer()
            
            if selectedExercises.contains(exercise) {
                Image(systemName: "circle.fill")
                    .foregroundColor(.black)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSelection(for: exercise)
        }
        .listRowBackground(Color.clear)
    }
}

#Preview {
    @Previewable @State var selected: Set<Exercise> = []
    
    ExerciseSelectionView(
        selectedExercises: $selected,
        workoutCategory: .resistance
    )
}


