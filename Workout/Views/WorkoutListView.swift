//
//  HomeView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode

    @State private var isCreatingNewWorkout = false
    @State private var newWorkout = WorkoutTemplate(title: "", order: 0)
    @State private var expandedCategories: Set<WorkoutCategory> = []
    @State private var selectedCategory: WorkoutCategory = .resistance


    @Query(sort: \WorkoutTemplate.order, order: .forward) private var workoutTemplates: [WorkoutTemplate]
    
    private var workoutsByCategory: [WorkoutCategory: [WorkoutTemplate]] {
        Dictionary(grouping: workoutTemplates, by: { $0.category })
    }

    @Query private var todaysEvents: [WorkoutEvent]
    
    init() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        _todaysEvents = Query(
            filter: #Predicate<WorkoutEvent> { event in
                event.date >= startOfDay && event.date < startOfTomorrow
            },
            sort: [SortDescriptor(\WorkoutEvent.order)]
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            
            List {
                Section(header: Text("Today's Workouts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                ) {
                    if todaysEvents.isEmpty {
                        Text("No workouts planned today")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowBackground(Color("Background"))
                    } else {
                        ForEach(todaysEvents) { event in
                            NavigationLink {
                                if let template = event.workoutTemplate {
                                    WorkoutView(workoutTemplate: template)
                                } else {
                                    WorkoutView(workoutEvent: event)
                                }
                            } label: {
                                Text(event.displayTitle)
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                    .padding(.vertical, 5)
                            }
                            .listRowBackground(Color("Background"))
                        }
                        .onDelete(perform: deleteTodayEvents)
                        .onMove(perform: moveTodayEvents)
                    }
                }

                
                Section(header: Text("Saved Workouts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                ) {

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(WorkoutCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color("Background"))

                    let categoryWorkouts = workoutsByCategory[selectedCategory] ?? []

                    if categoryWorkouts.isEmpty {
                        
                        Text("No saved workouts")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowBackground(Color("Background"))
                    } else {

                        ForEach(categoryWorkouts) { workout in
                            NavigationLink {
                                WorkoutView(workoutTemplate: workout)
                            } label: {
                                Text(workout.title)
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color("Background"))
                        }
                        .onDelete { offsets in
                            deleteWorkoutsForCategory(offsets, category: selectedCategory)
                        }
                        .onMove { source, destination in
                            moveWorkoutsForCategory(source, destination, category: selectedCategory)
                        }
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
                if !workoutTemplates.isEmpty {
                    EditButton()
                        .foregroundColor(.black)
                        .tint(.black)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: CreateWorkoutView(
                        workoutTemplate: newWorkout,
                        isNewWorkout: true,
                        workoutCategory: .resistance,
                        onSave: { workout in
                            addWorkout(workout)
                            newWorkout = WorkoutTemplate(title: "", order: 0)
                        }
                    )
                ) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    private func deleteTodayEvents(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(todaysEvents[index])
        }
        try? context.save()
    }

    private func moveTodayEvents(_ source: IndexSet, _ destination: Int) {
        var reordered = todaysEvents
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, event) in reordered.enumerated() {
            event.order = index
        }

        try? context.save()
    }
    
    private func addWorkout(_ workoutTemplate: WorkoutTemplate) {
        let nextOrder = (workoutTemplates.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        workoutTemplate.order = nextOrder
        context.insert(workoutTemplate)
    }

    private func deleteWorkouts(offsets: IndexSet) {
        for index in offsets {
            context.delete(workoutTemplates[index])
        }
    }
    
    private func moveWorkouts(offsets: IndexSet, newOffset: Int) {
        var reordered = workoutTemplates
        reordered.move(fromOffsets: offsets, toOffset: newOffset)
        
        for (index, workout) in reordered.enumerated() {
            if workout.order != index {
                workout.order = index
            }
        }
    }
    
    private func deleteWorkoutsForCategory(_ offsets: IndexSet, category: WorkoutCategory) {
        guard let categoryWorkouts = workoutsByCategory[category] else { return }
        let toDelete = offsets.map { categoryWorkouts[$0] }

        toDelete.forEach { context.delete($0) }
        try? context.save()
        
        if workoutTemplates.isEmpty {
            editMode?.wrappedValue = .inactive
        }
    }

    private func moveWorkoutsForCategory(_ source: IndexSet, _ destination: Int, category: WorkoutCategory) {
        guard var categoryWorkouts = workoutsByCategory[category] else { return }
        categoryWorkouts.move(fromOffsets: source, toOffset: destination)

        for (index, workout) in categoryWorkouts.enumerated() {
            workout.order = index
        }
        try? context.save()
    }
}

#Preview {
    WorkoutListView()
}
