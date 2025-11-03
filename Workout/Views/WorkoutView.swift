//
//  WorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//

import SwiftUI

/// View displaying a single workout, its exercises, and a built-in timer with laps.
struct WorkoutView: View {
    // MARK: - Bindings & State
    
    /// The workout being displayed and editable via child views.
    @Bindable var workoutTemplate: WorkoutTemplate
    
    /// Tracks whether the workout is in editing mode.
    @State private var isEditing = false
    
    /// Optional workout notes (currently not displayed).
    @State private var notes: String = ""
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            
            Divider()
            
            // MARK: - Exercise List
            if workoutTemplate.workoutExercises.isEmpty {
                Text("No exercises added yet")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                List {
                    ForEach(workoutTemplate.workoutExercises.sorted(by: { $0.order < $1.order }), id: \.id) { workoutExercise in
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 5) {
                                if let target = workoutExercise.targetNote, !target.isEmpty {
                                    Text("Target: \(target)")
                                }
                                if let notes = workoutExercise.notes, !notes.isEmpty {
                                    Text("Notes: \(notes)")
                                        .foregroundColor(.gray)
                                }
                                // Placeholder for set-tracking UI (future step)
                                Text("Sets will go here")
                                    .foregroundColor(.secondary)
                            }
                        } label: {
                            Text(workoutExercise.exercise.name)
                                .font(.system(.title3, weight: .semibold))
                                .padding(.vertical, 20)
                                .padding(.horizontal, 10)
                        }
                        .listRowBackground(Color("Background"))
                        .listRowInsets(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                    }
                }
                .listStyle(.plain)
                .padding(.trailing, 20)
                .tint(.black)
            }

            Spacer()
            
        }
        // MARK: - View Styling
        .edgesIgnoringSafeArea(.bottom)
        .foregroundColor(.black)
        .background(Color("Background"))
        .navigationTitle(workoutTemplate.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        // Navigate to workout editing view
        .navigationDestination(isPresented: $isEditing) {
            CreateWorkoutView(
                workoutTemplate: workoutTemplate,
                isNewWorkout: false
            )
        }
    }
}

// MARK: - Preview
#Preview {
    WorkoutView(
        workoutTemplate: WorkoutTemplate(title: "Leg Day")
    )
}
