//
//  HomeView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

struct WorkoutsView: View {
    @Environment(\.editMode) private var editMode
    @State private var isEditing: Bool = false

    var workouts: [Workout]
    var addWorkout: () -> Void
    var deleteWorkouts: (IndexSet) -> Void
    var moveWorkouts: (IndexSet, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top Buttons
            HStack {
                if !workouts.isEmpty {
                    Button(action: {
                        withAnimation {
                            isEditing.toggle()
                            editMode?.wrappedValue = isEditing ? .active : .inactive
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
                    addWorkout()
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
                Text("Workouts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)

            Divider()

            // MARK: - Workout List
            List {
                ForEach(workouts) { workout in
                    NavigationLink {
                        CreateWorkoutView(workout: .constant(workout), isNewWorkout: false)
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
                    .listRowSeparatorTint(.gray)
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

    WorkoutsView(
        workouts: sampleWorkouts,
        addWorkout: { sampleWorkouts.append(Workout(title: "New Workout", order: sampleWorkouts.count)) },
        deleteWorkouts: { offsets in sampleWorkouts.remove(atOffsets: offsets) },
        moveWorkouts: { source, destination in sampleWorkouts.move(fromOffsets: source, toOffset: destination) }
    )
}
