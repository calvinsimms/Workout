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
    @Environment(\.modelContext) private var context
    
    @Environment(\.editMode) private var editMode
    
    @State private var isCreatingNewWorkout = false
    
    @State private var newWorkout = Workout(title: "", order: 0)

    @State private var expandedCategories: Set<WorkoutCategory> = []
    
    // MARK: - Input Data and Actions
    
    @Query(sort: \Workout.order, order: .forward) private var workouts: [Workout]
    
    private var workoutsByCategory: [WorkoutCategory: [Workout]] {
        Dictionary(grouping: workouts, by: { $0.category })
    }

    
    // The list of workouts to display.
//    let workouts: [Workout]
    
    @Query private var todaysEvents: [WorkoutEvent]
    
    init() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        _todaysEvents = Query(
            filter: #Predicate<WorkoutEvent> { event in
                event.date >= startOfDay && event.date < startOfTomorrow
            },
            sort: [SortDescriptor(\.startTime, order: .forward)]
        )
    }



    // MARK: - Body
    var body: some View {
        
            VStack(spacing: 0) {
                        
                // MARK: - Workout List
                List {
                    
                    // Section for today's planned workouts
                    Section(header: Text("Today's Workouts")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    ) {
                        if todaysEvents.isEmpty {
                            Text("No workouts planned today")
                                .foregroundColor(.gray)
                                .italic()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .listRowBackground(Color("Background"))
                        } else {
                            ForEach(todaysEvents) { event in
                                NavigationLink {
                                    WorkoutView(workout: event.workout)
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
                                    .padding(.vertical, 5)
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
                                let categoryWorkouts = workoutsByCategory[category] ?? []

                                // Show the list of workouts for this category
                                ForEach(categoryWorkouts) { workout in
                                    NavigationLink {
                                        WorkoutView(workout: workout)
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
                                
                            } label: {
                                Text(category.rawValue)
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                    .padding(.vertical, 5)
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
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                   if !workouts.isEmpty {
                       EditButton()
                           .foregroundColor(.black)
                           .tint(.black)
                   }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                   NavigationLink(
                       destination: CreateWorkoutView(
                           workout: newWorkout,
                           isNewWorkout: true,
                           workoutCategory: .resistance,
                           onSave: { workout in
                               addWorkout(workout)
                               newWorkout = Workout(title: "", order: 0)
                           }
                       )
                   ) {
                       Image(systemName: "plus")
                           .font(.title3)
                           .foregroundColor(.black)
                   }
                }
            }
    }
    
    // MARK: - Data Management Methods
   
    private func addWorkout(_ workout: Workout) {
        let nextOrder = (workouts.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        workout.order = nextOrder
        context.insert(workout)
    }

    private func deleteWorkouts(offsets: IndexSet) {
        for index in offsets {
            context.delete(workouts[index])
        }
    }
    
    private func moveWorkouts(offsets: IndexSet, newOffset: Int) {
        var reordered = workouts
        reordered.move(fromOffsets: offsets, toOffset: newOffset)
        
        for (index, workout) in reordered.enumerated() {
            if workout.order != index {
                workout.order = index
            }
        }
    }
    
    // MARK: - Helper Functions

    private func deleteWorkoutsForCategory(_ offsets: IndexSet, category: WorkoutCategory) {
        guard let categoryWorkouts = workoutsByCategory[category] else { return }
        let toDelete = offsets.map { categoryWorkouts[$0] }

        toDelete.forEach { context.delete($0) }
        try? context.save()
        
        if workouts.isEmpty {
            editMode?.wrappedValue = .inactive
        }
    }

    private func moveWorkoutsForCategory(_ source: IndexSet, _ destination: Int, category: WorkoutCategory) {
        // Filter out workouts of the given category
        guard var categoryWorkouts = workoutsByCategory[category] else { return }
        categoryWorkouts.move(fromOffsets: source, toOffset: destination)

        // Apply new order within that category only
        for (index, workout) in categoryWorkouts.enumerated() {
            workout.order = index
        }
        try? context.save()

    }

}

// MARK: - Preview
#Preview {
    WorkoutListView()
}
