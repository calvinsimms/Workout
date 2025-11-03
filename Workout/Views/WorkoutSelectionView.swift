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
    @Query(sort: [SortDescriptor(\WorkoutTemplate.title)]) private var workoutTemplates: [WorkoutTemplate]
    
    @State private var selectedWorkout: WorkoutTemplate?
    @State private var date: Date
    @State private var eventTitle: String = ""
    @State private var showingExerciseSheet = false
    @State private var selectedExercises: Set<Exercise> = []
    @State private var selectedCategory: WorkoutCategory = .resistance

        
    @State private var selectedType = "NEW"
    let newOrSaved = ["NEW", "SAVED"]
    
    init(defaultDate: Date) {
           _date = State(initialValue: defaultDate)
       }
    

    var body: some View {
        
        NavigationStack {
            VStack(spacing: 10) {
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Picker("Select new or saved workout", selection: $selectedType) {
                    ForEach(newOrSaved, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.segmented)
                
                
                if selectedType == "SAVED" {
                    Section("SELECT WORKOUT") {
                        Picker("Select Workout", selection: $selectedWorkout) {
                            ForEach(workoutTemplates) { workoutTemplate in
                                Text(workoutTemplate.title).tag(Optional(workoutTemplate))
                            }
                        }
                    }
                    .font(.headline)
                    
                } else {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WORKOUT NAME")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("Title", text: $eventTitle)
                            .textFieldStyle(.plain)
                        
                        Text("CATERGORY")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(WorkoutCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(!selectedExercises.isEmpty)
                        
                        if !selectedExercises.isEmpty {
                            Text("Category locked - remove all exercises to change")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        
                        HStack {
                            Text("EXERCISES")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button {
                                showingExerciseSheet = true
                            } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.glass)
                        }
                        
                        if selectedExercises.isEmpty {
                            Text("No exercises selected")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(Array(selectedExercises).sorted(by: { $0.name < $1.name }), id: \.id) { exercise in
                                Text("• \(exercise.name)")
                                    .font(.body)
                            }
                        }
                        
                        
                    }
                    
                }
                
                Spacer()
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .background(Color("Background"))
            .tint(.black)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkoutEvent()
                        dismiss()
                    }
                    .disabled(selectedType == "SAVED" && selectedWorkout == nil)
                }
            }
            .sheet(isPresented: $showingExerciseSheet) {
                ExerciseSelectionView(
                    selectedExercises: $selectedExercises,
                    workoutCategory: .resistance // or another default, if you want
                )
            }
        }

    }
    
    private func saveWorkoutEvent() {
        // MARK: - SAVED TEMPLATE PATH
        if selectedType == "SAVED" {
            guard let selectedWorkout else { return }

            // Fetch the selected workout into the current model context
            let id = selectedWorkout.persistentModelID
            let descriptor = FetchDescriptor<WorkoutTemplate>(
                predicate: #Predicate { $0.persistentModelID == id },
                sortBy: []
            )
            
            guard let fetchedTemplate = try? context.fetch(descriptor).first else {
                assertionFailure("WorkoutTemplate not found in this context")
                return
            }
            
            // Create a new WorkoutEvent linked to that template
            let newEvent = WorkoutEvent(
                date: date,
                title: eventTitle.isEmpty ? nil : eventTitle,
                workoutTemplate: fetchedTemplate
            )
            
            context.insert(newEvent)
            
            do {
                try context.save()
                print("✅ Saved event from template: \(fetchedTemplate.title)")
            } catch {
                print("⚠️ Failed to save template-based event: \(error.localizedDescription)")
            }
            
            return
        }
        
        // MARK: - NEW EVENT PATH
        // The user is creating a new workout from scratch with a title + exercises
        let newEvent = WorkoutEvent(
            date: date,
            title: eventTitle.isEmpty ? nil : eventTitle
        )
        
        // Attach selected exercises to the event
        for (index, exercise) in selectedExercises.sorted(by: { $0.name < $1.name }).enumerated() {
            let workoutExercise = WorkoutExercise(
                notes: nil,
                targetNote: nil,
                targetMode: .simple,
                order: index,
                workoutEvent: newEvent,
                exercise: exercise
            )
            newEvent.workoutExercises.append(workoutExercise)
        }
        
        context.insert(newEvent)
        
        do {
            try context.save()
            print("✅ Saved new custom event with \(selectedExercises.count) exercises.")
        } catch {
            print("⚠️ Failed to save new workout event: \(error.localizedDescription)")
        }
    }

}

#Preview {
    WorkoutSelectionView(defaultDate: Date())
}

