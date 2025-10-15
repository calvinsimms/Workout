//
//  ExercisesView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI

// A view that displays a list of exercises, allows users to add, edit, delete, and reorder them.
// Acts as the main exercise management screen.
struct ExercisesView: View {
    // MARK: - State Properties
    
    // Stores the list of exercises displayed in this view.
    @State private var exercises: [Exercise] = []
    
    // Controls whether the list is currently in editing mode (for delete/move actions).
    @State private var isEditing = false
    
    // Controls the environment edit mode state of the list.
    @State private var editMode: EditMode = .inactive
    
    // Temporary `Exercise` instance used when creating a new exercise.
    @State private var newExercise = Exercise(name: "")
    
    // Controls whether the create exercise view is currently presented.
    @State private var creatingExercise = false
    
    // Custom initializer allows passing an existing list of exercises (for previews or parent injection).
    init(exercises: [Exercise] = []) {
        _exercises = State(initialValue: exercises)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - Top Bar
                HStack {
                    // Edit button appears only if the list is not empty
                    if !exercises.isEmpty {
                        Button(action: {
                            // Toggle editing mode with animation
                            withAnimation {
                                isEditing.toggle()
                                editMode = isEditing ? .active : .inactive
                            }
                        }) {
                            // Switches between "pencil" and "checkmark" icons
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding(10)
                                .background(Color("Button").opacity(0.9))
                                .cornerRadius(30)
                                .shadow(radius: 2)
                                .padding(.bottom, 10)
                        }
                    }
                    
                    Spacer()
                    
                    // Main title
                    Text("Exercises")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Plus button to create a new exercise
                    Button(action: {
                        newExercise = Exercise(name: "")
                        creatingExercise = true
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
                
                // MARK: - Exercise List
                List {
                    ForEach($exercises) { $exercise in
                        // Each exercise opens its detail/edit view
                        NavigationLink(value: exercise) {
                            HStack {
                                Text(exercise.name)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color("Background"))
                        .listRowSeparatorTint(.gray)
                    }
                    // Swipe to delete
                    .onDelete(perform: deleteExercise)
                    // Drag to reorder
                    .onMove(perform: moveExercise)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
                }
                .listStyle(.plain)
                .environment(\.editMode, $editMode)
            }
            .background(Color("Background"))
            
            // MARK: - Navigation Destinations
            
            // Opens CreateExerciseView for an existing exercise
            .navigationDestination(for: Exercise.self) { exercise in
                if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                    CreateExerciseView(
                        exercise: $exercises[index],
                        isNewExercise: false,
                        onSave: nil // Save handled automatically on dismiss or navigation pop
                    )
                }
            }
            
            // Opens CreateExerciseView for adding a new exercise
            .navigationDestination(isPresented: $creatingExercise) {
                CreateExerciseView(
                    exercise: $newExercise,
                    isNewExercise: true,
                    onSave: {
                        // Append the new exercise to the list
                        exercises.append(newExercise)
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Deletes exercises at specified offsets.
    // Automatically exits edit mode if the list becomes empty.
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        if exercises.isEmpty {
            isEditing = false
            editMode = .inactive
        }
    }
    
    // Moves exercises from one position to another.
    private func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    ExercisesView(
        exercises: [
            Exercise(name: "Squats"),
            Exercise(name: "Deadlifts"),
            Exercise(name: "Bench Press")
        ]
    )
}
