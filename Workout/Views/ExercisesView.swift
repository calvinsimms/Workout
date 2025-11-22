//
//  ExercisesView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name, order: .forward) private var exercises: [Exercise]
    
    @State private var creatingExercise = false
    @State private var newExercise = Exercise(name: "")
    @State private var selectedExercise: Exercise? = nil
    @State private var selectedCategory: WorkoutCategory = .resistance
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                List {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(WorkoutCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color("Background"))
                    
                    if selectedCategory == .resistance {
                        ForEach(SubCategory.allCases) { sub in
                            DisclosureGroup(sub.rawValue) {
                                ForEach(exercisesFor(subCategory: sub)) { exercise in
                                    exerciseRow(exercise)
                                }
                                .onDelete { indexSet in
                                    deleteExercises(in: exercisesFor(subCategory: sub), at: indexSet)
                                }
                            }
                            .bold()
                            .listRowBackground(Color("Background"))
                        }
                    } else {
                        ForEach(exercisesFor(category: selectedCategory)) { exercise in
                            exerciseRow(exercise)
                        }
                        .onDelete { indexSet in
                            deleteExercises(in: exercisesFor(category: selectedCategory), at: indexSet)
                        }
                    }
                }
                .listStyle(GroupedListStyle())
                .scrollContentBackground(.hidden)
                .navigationTitle("Exercises")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                            .foregroundColor(.black)
                            .tint(.black)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            newExercise = Exercise(name: "")
                            creatingExercise = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                }
                
                .sheet(isPresented: $creatingExercise) {
                    NavigationStack {
                        CreateExerciseView(
                            exercise: $newExercise,
                            isNewExercise: true,
                            onSave: {
                                modelContext.insert(newExercise)
                            }
                        )
                    }
                }
                
                .sheet(item: $selectedExercise) { exercise in
                    NavigationStack {
                        CreateExerciseView(
                            exercise: Binding(
                                get: { exercise },
                                set: { updated in
                                    modelContext.insert(updated)
                                }
                            ),
                            isNewExercise: false
                        )
                    }
                }
            }
        }
        
    }
    
    private func exercisesFor(category: WorkoutCategory) -> [Exercise] {
        exercises.filter { $0.category == category }
    }
    
    private func exercisesFor(subCategory: SubCategory) -> [Exercise] {
        exercises.filter { $0.subCategory == subCategory }
    }
    
    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button {
            selectedExercise = exercise
        } label: {
            HStack {
                Text(exercise.name)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color("Background"))
    }
    
    private func deleteExercises(in filtered: [Exercise], at offsets: IndexSet) {
        for index in offsets {
            let exerciseToDelete = filtered[index]
            modelContext.delete(exerciseToDelete)
        }
    }
}

#Preview {
    ExercisesView()
}
