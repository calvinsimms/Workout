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
    @Binding var selectedExercises: Set<Exercise>
    
    @Query(sort: \Exercise.name, order: .forward) private var allExercisesQuery: [Exercise]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCreateExercise = false
    @State private var newExercise = Exercise(name: "")
    @State private var expandedGroups: Set<SubCategory> = []
    @State private var showConfirmButton = false
    
    @State private var favoritesExpanded: Bool = false

    
    var workoutCategory: WorkoutCategory
    
    private var filteredExercises: [Exercise] {
        allExercises.filter { $0.category == workoutCategory }
    }
    
    var exercises: [Exercise]?
    
    private var allExercises: [Exercise] {
        exercises ?? allExercisesQuery
    }
    
    
    var body: some View {
        List {
            
            Section {
                let favoriteExercises = allExercises.filter { $0.category == .resistance && $0.isFavorite }
                
                DisclosureGroup(
                    "Favorites",
                    isExpanded: $favoritesExpanded
                ) {
                    if favoriteExercises.isEmpty {
                        Text("No favorites yet")
                            .fontWeight(.regular)
                            .foregroundColor(.gray.opacity(0.6))
                            .italic()
                    } else {
                        ForEach(favoriteExercises, id: \.id) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
                .onAppear {
                    // Expand if there are favorites, otherwise collapsed
                    favoritesExpanded = !favoriteExercises.isEmpty
                }
            }
            .listRowBackground(Color("Background"))


            
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
            Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                .fontWeight(.regular)
                .foregroundColor(exercise.isFavorite ? .black : .gray.opacity(0.4))
                .onTapGesture {
                    if let index = allExercises.firstIndex(where: { $0.id == exercise.id }) {
                        allExercises[index].isFavorite.toggle()
                    }
                }
            
            Text(exercise.name)
            
            Spacer()
            
            if selectedExercises.contains(exercise) {
                Image(systemName: "circle.fill")
                    .foregroundColor(.black)
                    .fontWeight(.regular)

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
    
    // Mock exercises
    let mockExercises: [Exercise] = [
        Exercise(name: "Squat", category: .resistance, subCategory: .legs, isBodyweight: false, isFavorite: true),
        Exercise(name: "Push-up", category: .resistance, subCategory: .chest, isBodyweight: true),
        Exercise(name: "Pull-up", category: .resistance, subCategory: .back, isBodyweight: true, isFavorite: true),
        Exercise(name: "Bicep Curl", category: .resistance, subCategory: .biceps, isBodyweight: false),
        Exercise(name: "Lunge", category: .resistance, subCategory: .legs, isBodyweight: true),
        Exercise(name: "Plank", category: .resistance, subCategory: .abs, isBodyweight: true),
        Exercise(name: "Bench Press", category: .resistance, subCategory: .chest, isBodyweight: false)
    ]
    
    ExerciseSelectionView(
        selectedExercises: $selected,
        workoutCategory: .resistance,
        exercises: mockExercises
    )
}


