//
//  HomeView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

struct WorkoutListView: View {
    @Environment(\.editMode) private var editMode
    @State private var isEditing: Bool = false
    @State private var isCreatingNewWorkout = false
    @State private var newWorkout = Workout(title: "", order: 0, exercises: [])

    let workouts: [Workout]
    var addWorkout: (Workout) -> Void
    var deleteWorkouts: (IndexSet) -> Void
    var moveWorkouts: (IndexSet, Int) -> Void
    
    @Binding var isNavBarHidden: Bool

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top Buttons
            HStack {
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
                        .background((Color("Button").opacity(0.9)))
                        .cornerRadius(30)
                        .shadow(radius: 2)
                        .padding(.bottom, 10)

                }
                .disabled(workouts.isEmpty)
            
                Spacer()
                
                Text("Workouts")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                
                Spacer()

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

            // MARK: - Workout List with Sections
            List {
                
                Section(header: Text("Today's Workouts")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        
                        
                    ) {
                        // Stub content
                        Text("No workouts planned today")
                            .font(.system(.title2, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowBackground(Color("Background"))
                    }
                    
                Section(header: Text("Saved Workouts")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                ){
                }
                
                ForEach(WorkoutCategory.allCases) { category in
                    Section(header: Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.black)
                    ) {
                        ForEach(workouts.filter { $0.category == category }) { workout in
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
                            .listRowInsets(EdgeInsets(
                                   top: 10,
                                   leading: 0,
                                   bottom: 10,
                                   trailing: 0))
                        }
                        .onDelete { offsets in
                            deleteWorkoutsForCategory(offsets, category: category)
                        }
                        .onMove { source, destination in
                            moveWorkoutsForCategory(source, destination, category: category)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .scrollContentBackground(.hidden)
            .environment(\.editMode, editMode)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
        }
        .background(Color("Background"))
    }

    // MARK: - Helper Functions for Category-based Delete/Move
    private func deleteWorkoutsForCategory(_ offsets: IndexSet, category: WorkoutCategory) {
        let categoryWorkouts = workouts.filter { $0.category == category }
        let idsToDelete = offsets.map { categoryWorkouts[$0].id }

        deleteWorkouts(IndexSet(
            workouts.enumerated().compactMap { idsToDelete.contains($0.element.id) ? $0.offset : nil }
        ))

        if workouts.isEmpty {
            isEditing = false
            editMode?.wrappedValue = .inactive
        }
    }

    private func moveWorkoutsForCategory(_ source: IndexSet, _ destination: Int, category: WorkoutCategory) {
        var categoryWorkouts = workouts.filter { $0.category == category }
        categoryWorkouts.move(fromOffsets: source, toOffset: destination)

        var reordered: [Workout] = []
        for cat in WorkoutCategory.allCases {
            if cat == category {
                reordered.append(contentsOf: categoryWorkouts)
            } else {
                reordered.append(contentsOf: workouts.filter { $0.category == cat })
            }
        }
    }
}



#Preview {
    @Previewable @State var sampleWorkouts: [Workout] = [
        Workout(title: "Leg Day", order: 0, exercises: [], category: .weightlifting),
        Workout(title: "Push Day", order: 1, exercises: [], category: .weightlifting),
        Workout(title: "Run", order: 2, exercises: [], category: .cardio),
        Workout(title: "Tennis", order: 3, exercises: [], category: .other)
    ]

    WorkoutListView(
        workouts: sampleWorkouts,
        addWorkout: { _ in sampleWorkouts.append(Workout(title: "New Workout", order: sampleWorkouts.count)) },
        deleteWorkouts: { offsets in sampleWorkouts.remove(atOffsets: offsets) },
        moveWorkouts: { source, destination in sampleWorkouts.move(fromOffsets: source, toOffset: destination) },
        isNavBarHidden: .constant(false)
    )
}
