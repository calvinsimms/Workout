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
    @State private var showingCreateExercise = false
    
    // A temporary exercise object used for creating new exercises.
    @State private var newExercise = Exercise(name: "")

    var body: some View {
        VStack(spacing: 0) {
            
            // Header Bar
            HStack {
                
                // Check button: Dismiss and confirm selection
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color("Button").opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                        .padding(.bottom, 10)
                }
                
                Spacer()
                
                // Title centered in the header
                Text("Select Exercises")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                
                Spacer()
                
                // Plus button: Opens sheet to create new exercise
                Button(action: {
                    newExercise = Exercise(name: "") // Reset temporary exercise
                    showingCreateExercise = true      // Show create sheet
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color("Button").opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                        .padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 20)
            
            Divider()
            
            // Exercise List
            List(allExercises, id: \.id) { exercise in
                HStack {
                    // Exercise name
                    Text(exercise.name)
                    
                    Spacer()
                    
                    // Show a filled circle if the exercise is selected
                    if selectedExercises.contains(exercise) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.black)
                    }
                }
                // Makes the entire row tappable
                .contentShape(Rectangle())
                
                // Tapping toggles selection state
                .onTapGesture {
                    toggleSelection(for: exercise)
                }
                
                // Transparent row background for cleaner custom background
                .listRowBackground(Color.clear)
            }
            .foregroundStyle(.black)
            .fontWeight(.bold)
            .listStyle(.plain)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70)
            }
        }
        // Background & Navigation Customization
        .background(Color("Background"))
        .toolbar {
            // (Optional toolbar content can go here later)
        }
        .navigationBarBackButtonHidden(true) // Hide default back button
        
        // Sheet for Creating a New Exercise
        .sheet(isPresented: $showingCreateExercise) {
            NavigationStack {
                CreateExerciseView(
                    exercise: $newExercise,
                    isNewExercise: true,
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
}

#Preview {
    @Previewable @State var selected: Set<Exercise> = []
    ExerciseSelectionView(selectedExercises: $selected)
}


