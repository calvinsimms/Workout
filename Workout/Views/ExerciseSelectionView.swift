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
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCreateExercise = false
    @State private var newExercise = Exercise(name: "")

    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                
                Button(action: {dismiss()
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
                
                Text("Select Exercises")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                
                Spacer()
                
                Button(action: {
                    newExercise = Exercise(name: "")
                    showingCreateExercise = true
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
            
            List(allExercises, id: \.id) { exercise in
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
            .foregroundStyle(.black)
            .fontWeight(.bold)
            .listStyle(.plain)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70)
            }
        }
        .background(Color("Background"))
        .toolbar {
        }
        .navigationBarBackButtonHidden(true)

        .sheet(isPresented: $showingCreateExercise) {
            NavigationStack {
                CreateExerciseView(
                    exercise: $newExercise,
                    isNewExercise: true,
                    onSave: {
                        modelContext.insert(newExercise)
                        showingCreateExercise = false
                    }
                )
            }
        }
      

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
}


