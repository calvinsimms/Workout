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

    var workouts: [Workout]
    var addWorkout: (Workout) -> Void
    var deleteWorkouts: (IndexSet) -> Void
    var moveWorkouts: (IndexSet, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top Buttons
            HStack {
                Button(action: {
                    if !workouts.isEmpty { // Only toggle edit mode if workouts exist
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
                }
                .disabled(workouts.isEmpty)
            
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
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            HStack {
                Text("Workouts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            Divider()

            // MARK: - Workout List
            List {
                ForEach(workouts) { workout in
                    NavigationLink {
                        WorkoutView(workout: workout)
                    } label: {
                        HStack {
                            Text(workout.title)
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
                }
                .onDelete { offsets in
                    deleteWorkouts(offsets)
                    if workouts.count - offsets.count <= 0 {
                        isEditing = false
                        editMode?.wrappedValue = .inactive
                    }
                }
                .onMove(perform: moveWorkouts)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
            }
            .listStyle(.plain)
            .environment(\.editMode, editMode)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
        }
        .background(Color("Background"))
    }
}


#Preview {
    @Previewable @State var sampleWorkouts: [Workout] = [
        Workout(title: "Morning Routine", order: 0, exercises: []),
        Workout(title: "Evening Strength", order: 1, exercises: [])
    ]

    WorkoutListView(
        workouts: sampleWorkouts,
        addWorkout: { _ in sampleWorkouts.append(Workout(title: "New Workout", order: sampleWorkouts.count)) },
        deleteWorkouts: { offsets in sampleWorkouts.remove(atOffsets: offsets) },
        moveWorkouts: { source, destination in sampleWorkouts.move(fromOffsets: source, toOffset: destination) }
    )
}
