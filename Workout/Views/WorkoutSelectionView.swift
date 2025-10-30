//
//  WorkoutSelectionView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-11.
//

import SwiftUI
import SwiftData

struct WorkoutSelectionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Workout.title)]) private var workouts: [Workout]
    
    @State private var selectedWorkout: Workout?
    @State private var date: Date
        
    @State private var selectedType = "NEW"
    let newOrSaved = ["NEW", "SAVED"]
    
    init(defaultDate: Date) {
           _date = State(initialValue: defaultDate)
       }
    

    var body: some View {
        
        VStack(spacing: 10) {
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Save") {
                    saveWorkoutEvent()
                    dismiss()
                }
                .disabled(selectedWorkout == nil)
            }
            
            DatePicker("Date", selection: $date, displayedComponents: .date)
            
            Picker("Select new or saved workout", selection: $selectedType) {
                ForEach(newOrSaved, id: \.self) { type in
                    Text(type)
                }
            }
            .pickerStyle(.segmented)
            
            
            if selectedType == "SAVED" {
                Section("Workout") {
                    Picker("Select Workout", selection: $selectedWorkout) {
                        ForEach(workouts) { workout in
                            Text(workout.title).tag(Optional(workout))
                        }
                    }
                }
            } else {
                
            }
            
            Spacer()
            
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .background(Color("Background"))
        .tint(.black)

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
            workout: workoutInContext
        )
        context.insert(newEvent)
        do { try context.save() } catch {
            print("Failed to save event: \(error)")
    }
}

}

#Preview {
    WorkoutSelectionView(defaultDate: Date())
}

