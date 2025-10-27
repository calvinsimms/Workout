//
//  HomeView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI
import SwiftData
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
    @State private var newWorkout = Workout(title: "", order: 0)

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
    
    @State private var todaysEvents: [WorkoutEvent] = []
    
    @Environment(\.modelContext) private var context

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
                        workout: newWorkout,
                        isNewWorkout: true,
                        isNavBarHidden: $isNavBarHidden,
                        workoutCategory: .resistance,
                        onSave: { workout in
                            addWorkout(workout)
                            newWorkout = Workout(title: "", order: 0)
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
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.bottom, 15)
                        .padding(.top, 5)
                ) {
                    if todaysEvents.isEmpty {
                        Text("No workouts planned today")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowBackground(Color("Background"))
                    } else {
                        ForEach(todaysEvents) { event in
                            NavigationLink {
                                WorkoutView(workout: event.workout, isNavBarHidden: $isNavBarHidden)
                            } label: {
                                HStack {
                                    Text(event.workout.title)
                                        .font(.title3.bold())
                                        .foregroundColor(.black)
                                    Spacer()
                                    if let time = event.startTime {
                                        Text(time.formatted(date: .omitted, time: .shortened))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .listRowBackground(Color("Background"))
                        }
                    }
                }
                
                // Section for saved workouts (currently empty, can be expanded)
                Section(header: Text("Saved Workouts")
                        .font(.title2)
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
                        
                            // Show the list of workouts for this category
                            ForEach(categoryWorkouts) { workout in
                                NavigationLink {
                                    WorkoutView(workout: workout, isNavBarHidden: $isNavBarHidden)
                                } label: {
                                    HStack {
                                        Text(workout.title)
                                            .font(.title3.bold())
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 20)
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowBackground(Color("Background"))
                                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 15))
                                .tint(.black)
                                
                            }
                            .onDelete { offsets in
                                deleteWorkoutsForCategory(offsets, category: category)
                            }
                            .onMove { source, destination in
                                moveWorkoutsForCategory(source, destination, category: category)
                            }
                            
                            NavigationLink(
                                destination: CreateWorkoutView(
                                    workout: Workout(title: "", order: 0, category: category),
                                   isNewWorkout: true,
                                   isNavBarHidden: $isNavBarHidden,
                                   workoutCategory: category,
                                   onSave: { workout in
                                       addWorkout(workout)
                                       newWorkout = Workout(title: "", order: 0)
                                   }
                               )
                           ) {
                               HStack {
                                   Image(systemName: "plus.circle.fill")

                                   Text("Add \(category.rawValue.capitalized) Workout")
                                       .font(.title3)
                                       .fontWeight(.semibold)
                                       .foregroundColor(.black)
                                       .padding(.vertical, 10)
                               }
                         
                           }
                           .listRowBackground(Color("Background"))

                            
                        } label: {
                            Text(category.rawValue)
                                .font(.title3.bold())
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
        .onAppear {
            fetchTodaysEvents()
        }
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
    
    // Handles reordering of workouts within a specific category.
    //
    // Converts the local (category-specific) drag indices provided by SwiftUI’s `.onMove`
    // into global indices that correspond to positions in the full `workouts` array.
    // This allows the parent `moveWorkouts` closure to correctly update the SwiftData model.
    //
    // - Parameters:
    //   - source: The set of indices (relative to the category section) representing the moved items.
    //   - destination: The target index (relative to the category section) where the items are dropped.
    //   - category: The workout category being reordered.
    private func moveWorkoutsForCategory(_ source: IndexSet, _ destination: Int, category: WorkoutCategory) {
        
        // 1. Identify the global indices for all workouts within this category.
        //    These represent the positions of the category’s items in the full workouts array.
        let globalIndices = workouts.enumerated()
            .filter { $0.element.category == category }
            .map { $0.offset }
        
        // 2. Convert the local (category) source indices into their corresponding global indices.
        let globalSource = IndexSet(source.map { globalIndices[$0] })
        
        // 3. Determine the global destination index.
        //    If the drop is within the category bounds, map directly;
        //    otherwise, place after the last item in this category.
        let globalDestination: Int
        if destination < globalIndices.count {
            globalDestination = globalIndices[destination]
        } else {
            globalDestination = globalIndices.last! + 1
        }
        
        // 4. Delegate the move to the parent closure.
        //    This updates the persisted SwiftData model and reassigns workout order values.
        moveWorkouts(globalSource, globalDestination)
    }
        
    private func fetchTodaysEvents() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let descriptor = FetchDescriptor<WorkoutEvent>(
            predicate: #Predicate { event in
                event.date >= startOfDay && event.date < startOfTomorrow
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            todaysEvents = try context.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch today's events: \(error)")
            todaysEvents = []
        }
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
            category: .resistance   // Workout category
        ),
        Workout(
            title: "Push Day",
            order: 1,
            category: .resistance
        ),
        Workout(
            title: "Run",
            order: 2,
            category: .cardio
        )
//        Workout(
//            title: "Tennis",
//            order: 3,
//            category: .other
//        )
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
