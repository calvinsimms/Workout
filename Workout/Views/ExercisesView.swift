//
//  ExercisesView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI

struct ExercisesView: View {
    @State private var exercises: [Exercise] = []
    @State private var isEditing = false
    @State private var editMode: EditMode = .inactive
    
    // Temporary state for creating a new exercise
    @State private var newExercise = Exercise(name: "")
    @State private var creatingExercise = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Top Buttons
                HStack {
                    if !exercises.isEmpty {
                        Button(action: {
                            withAnimation {
                                isEditing.toggle()
                                editMode = isEditing ? .active : .inactive
                            }
                        }) {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .font(.title)
                                .foregroundColor(.black)
                                .padding(10)
                                .background(Color("Button").opacity(0.9))
                                .cornerRadius(30)
                                .shadow(radius: 2)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        newExercise = Exercise(name: "")
                        creatingExercise = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color("Button").opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // MARK: - Header
                HStack {
                    Text("Exercises")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                
                Divider()
                
                // MARK: - List
                List {
                    ForEach($exercises) { $exercise in
                        NavigationLink(value: exercise) {
                            HStack {
                                Text(exercise.name)
                                    .font(.system(.title, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 20)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color("Background"))
                        .listRowSeparatorTint(.gray)
                    }
                    .onDelete(perform: deleteExercise)
                    .onMove(perform: moveExercise)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
                }
                .listStyle(.plain)
                .environment(\.editMode, $editMode)
            }
            .background(Color("Background"))
            // MARK: - Navigation Destinations
            .navigationDestination(for: Exercise.self) { exercise in
                if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                    CreateExerciseView(
                        exercise: $exercises[index],
                        isNewExercise: false,
                        onSave: nil
                    )
                }
            }
            // MARK: - Create New Exercise Navigation
            .navigationDestination(isPresented: $creatingExercise) {
                CreateExerciseView(
                    exercise: $newExercise,
                    isNewExercise: true,
                    onSave: {
                        exercises.append(newExercise)
                    }
                )
            }
        }
    }
    
    // MARK: - Actions
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        if exercises.isEmpty {
            isEditing = false
            editMode = .inactive
        }
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    ExercisesView()
}
