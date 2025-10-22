//
//  AddWorkoutEventView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-22.
//

import SwiftUI
import SwiftData

struct AddWorkoutEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // Workouts fetched from SwiftData to choose from
    @Query(sort: [SortDescriptor(\Workout.title)]) private var workouts: [Workout]
    
    // Input fields
    @State private var selectedWorkout: Workout?
    @State private var date: Date
    @State private var startTime: Date = Date()
    
    init(defaultDate: Date) {
        _date = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    Picker("Select Workout", selection: $selectedWorkout) {
                        ForEach(workouts) { workout in
                            Text(workout.title).tag(Optional(workout))
                        }
                    }
                }
                
                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle("Add Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkoutEvent()
                        dismiss()
                    }
                    .disabled(selectedWorkout == nil)
                }
            }
        }
    }
    
    private func saveWorkoutEvent() {
        guard let selectedWorkout else { return }

        // Bring the workout into THIS context by persistentModelID
        let id = selectedWorkout.persistentModelID
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.persistentModelID == id },
            sortBy: []
        )
        guard
            let workoutInContext = try? context.fetch(descriptor).first
        else {
            assertionFailure("Workout not found in this context")
            return
        }

        let newEvent = WorkoutEvent(
            date: date,
            workout: workoutInContext,
            startTime: startTime
        )
        context.insert(newEvent)
        do { try context.save() } catch {
            print("Failed to save event: \(error)")
        }
    }

}

#Preview {
    AddWorkoutEventView(defaultDate: Date())
}
