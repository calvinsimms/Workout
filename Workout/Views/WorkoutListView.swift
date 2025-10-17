//
//  HomeView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

// Displays a list of workouts, categorized by type, and allows adding, deleting, and reordering workouts.
struct WorkoutListView: View {
    // MARK: - Environment and State
    
    // Access to the edit mode environment variable for the list.
    @Environment(\.editMode) private var editMode
    
    // Tracks whether the list is currently in editing mode.
    @State private var isEditing: Bool = false
    
    // Controls the presentation of a new workout creation view.
    @State private var isCreatingNewWorkout = false
    
    // Temporary workout object for creating a new workout.
    @State private var newWorkout = Workout(title: "", order: 0, exercises: [])
    
    // Tracks which workout categories are currently expanded in the list.
    // Each `WorkoutCategory` in this set represents an open DisclosureGroup.
    // Used to preserve expand/collapse state while navigating through workouts.
    @State private var expandedCategories: Set<WorkoutCategory> = []
    
    // MARK: - Input Data and Actions
    
    // The list of workouts to display.
    let workouts: [Workout]
    
    // Closure called to add a new workout to the list.
    var addWorkout: (Workout) -> Void
    
    // Closure called to delete workouts from the list at specified offsets.
    var deleteWorkouts: (IndexSet) -> Void
    
    // Closure called to move/reorder workouts in the list.
    var moveWorkouts: (IndexSet, Int) -> Void
    
    // Binding to control the visibility of the navigation bar in the parent view.
    @Binding var isNavBarHidden: Bool

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top Action Buttons
            HStack {
                // Edit mode toggle button
                Button(action: {
                    if !workouts.isEmpty {
                        withAnimation {
                            isEditing.toggle()
                            editMode?.wrappedValue = isEditing ? .active : .inactive
                        }
                    }
                }) {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .font(.title2)
                        .foregroundColor(workouts.isEmpty ? Color("Grayout") : .black)
                        .padding(10)
                        .background(Color("Button").opacity(0.9))
                        .cornerRadius(30)
                        .shadow(radius: 2)
                        .padding(.bottom, 10)
                }
                .disabled(workouts.isEmpty)
                
                Spacer()
                
                // Title
                Text("Workouts")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                
                Spacer()
                
                // Button to create a new workout
                NavigationLink(
                    destination: CreateWorkoutView(
                        workout: Bindable(newWorkout),
                        isNewWorkout: true,
                        onSave: { workout in
                            addWorkout(workout)
                            newWorkout = Workout(title: "", order: 0, exercises: [])
                        }
                    )
                ) {
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
            
            // MARK: - Workout List
            List {
                
                // Section for today's planned workouts
                Section(header: Text("Today's Workouts")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.bottom, 15)
                        .padding(.top, 10)
                ) {
                    Text("No workouts planned today")
                        .foregroundColor(.gray)
                        .italic()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowBackground(Color("Background"))
                }
                
                // Section for saved workouts (currently empty, can be expanded)
                Section(header: Text("Saved Workouts")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.bottom, 15)
                ) {
                    
                    // Sections for each workout category
                    ForEach(WorkoutCategory.allCases) { category in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedCategories.contains(category) },
                                set: { isExpanded in
                                    withAnimation {
                                        if isExpanded {
                                            expandedCategories.insert(category)
                                        } else {
                                            expandedCategories.remove(category)
                                        }
                                    }
                                }
                            )
                        ) {
                            let categoryWorkouts = workouts.filter { $0.category == category }
                            
                            if categoryWorkouts.isEmpty {
                                // Show a placeholder row when there are no workouts in this category
                                HStack {
                                    Text("No saved workouts")
                                        .foregroundColor(.gray)
                                        .italic()
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .listRowBackground(Color("Background"))
                            } else {
                                // Show the list of workouts for this category
                                ForEach(categoryWorkouts) { workout in
                                    NavigationLink {
                                        WorkoutView(workout: workout, isNavBarHidden: $isNavBarHidden)
                                    } label: {
                                        HStack {
                                            Text(workout.title)
                                                .font(.system(.title2, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 20)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .listRowBackground(Color("Background"))
                                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                                }
                                .onDelete { offsets in
                                    deleteWorkoutsForCategory(offsets, category: category)
                                }
                                .onMove { source, destination in
                                    moveWorkoutsForCategory(source, destination, category: category)
                                }
                            }
                        } label: {
                            Text(category.rawValue)
                                .font(.title2.bold())
                                .foregroundColor(.black)
                                .padding(.vertical, 10)
                        }
                        .listRowBackground(Color("Background"))
                        .tint(.black)
                        .padding(.leading, 20)

                    }
                }

            }
            .listStyle(GroupedListStyle())
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, editMode)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
        }
        .background(Color("Background"))
    }
    
    // MARK: - Helper Functions

    // Deletes workouts in a specific category while maintaining overall list offsets.
    // This is necessary because the list is divided into sections by category,
    // but the `deleteWorkouts` closure expects global indices.
    private func deleteWorkoutsForCategory(_ offsets: IndexSet, category: WorkoutCategory) {
        
        // 1. Filter workouts to only include those in the specified category.
        //    This maps the category-local indices from the List section to actual workouts.
        let categoryWorkouts = workouts.filter { $0.category == category }
        
        // 2. Extract the IDs of the workouts that need to be deleted.
        //    `offsets` are relative to the section, so we map them to the workout IDs.
        let idsToDelete = offsets.map { categoryWorkouts[$0].id }

        // 3. Map category-local IDs to global indices in the full `workouts` array.
        //    `enumerated()` gives us the index and element in the full array.
        //    `compactMap` returns only the global indices that match the IDs we want to delete.
        let globalOffsets = IndexSet(
            workouts.enumerated().compactMap { idsToDelete.contains($0.element.id) ? $0.offset : nil }
        )
        
        // 4. Call the delete closure with global indices.
        //    This updates the main workouts array in the parent or state.
        deleteWorkouts(globalOffsets)

        // 5. Exit editing mode if there are no workouts left.
        //    This ensures the UI correctly reflects that the list is empty.
        if workouts.isEmpty {
            isEditing = false
            editMode?.wrappedValue = .inactive
        }
    }

    // Reorders workouts within a specific category while preserving the order of other categories.
    // This is necessary to maintain sectioned ordering while supporting drag-and-drop.
    private func moveWorkoutsForCategory(_ source: IndexSet, _ destination: Int, category: WorkoutCategory) {
        
        // 1. Filter workouts to only include the ones in the specified category.
        var categoryWorkouts = workouts.filter { $0.category == category }
        
        // 2. Reorder the category-specific workouts using SwiftUI's IndexSet move operation.
        categoryWorkouts.move(fromOffsets: source, toOffset: destination)
        
        // 3. Reconstruct the full workouts array with updated category order.
        //    For all categories, append the reordered workouts for the moved category,
        //    and keep the original order for other categories.
        var reordered: [Workout] = []
        for cat in WorkoutCategory.allCases {
            if cat == category {
                reordered.append(contentsOf: categoryWorkouts)
            } else {
                reordered.append(contentsOf: workouts.filter { $0.category == cat })
            }
        }
        
        // 4. Note:
        //    Currently, `reordered` is only a local variable and does not update the state or binding.
        //    To make this functional, you would need to call a state updater or the parent closure
        //    like `moveWorkouts(IndexSet(...), destination)` with the new order.
    }

}

// MARK: - Preview
#Preview {
    // MARK: - Sample Data for Preview
    // This defines a stateful array of Workout objects to use in the preview.
    // @Previewable allows Xcode's canvas to update interactively when state changes.
    @Previewable @State var sampleWorkouts: [Workout] = [
        Workout(
            title: "Leg Day",          // Name of the workout
            order: 0,                  // Order for sorting purposes
            exercises: [],             // Empty list of exercises for simplicity
            category: .resistance   // Workout category
        ),
        Workout(
            title: "Push Day",
            order: 1,
            exercises: [],
            category: .resistance
        ),
        Workout(
            title: "Run",
            order: 2,
            exercises: [],
            category: .cardio
        ),
        Workout(
            title: "Tennis",
            order: 3,
            exercises: [],
            category: .other
        )
    ]

    // MARK: - WorkoutListView Preview
    // Initializes the WorkoutListView with the sample data above.
    // The closures simulate the add, delete, and move actions in a live preview environment.
    WorkoutListView(
        workouts: sampleWorkouts, // The data to display in the list

        // Closure for adding a new workout
        addWorkout: { _ in
            // Appends a new workout with a default title and order equal to the current count
            sampleWorkouts.append(
                Workout(title: "New Workout", order: sampleWorkouts.count)
            )
        },

        // Closure for deleting workouts
        deleteWorkouts: { offsets in
            // Removes the workouts at the specified offsets from the array
            sampleWorkouts.remove(atOffsets: offsets)
        },

        // Closure for moving/reordering workouts
        moveWorkouts: { source, destination in
            // Reorders the workouts array according to the source and destination indexes
            sampleWorkouts.move(fromOffsets: source, toOffset: destination)
        },

        // Binding controlling navigation bar visibility
        // In preview, we set it constant to false for simplicity
        isNavBarHidden: .constant(false)
    )
}
