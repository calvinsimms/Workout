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
    @Environment(\.editMode) private var editMode

    @Query(sort: [SortDescriptor(\WorkoutTemplate.title)]) private var workoutTemplates: [WorkoutTemplate]
    
    @State private var selectedWorkout: WorkoutTemplate?
    @State private var date: Date
    @State private var eventTitle: String = ""
    @State private var showingExerciseSheet = false
    @State private var selectedExercises: Set<Exercise> = []
    @State private var selectedCategory: WorkoutCategory = .resistance
    


        
    @State private var selectedType = "New"
    let newOrSaved = ["New", "Saved"]
    
    init(defaultDate: Date, sampleExercises: [Exercise]? = nil) {
         _date = State(initialValue: defaultDate)
         if let sampleExercises {
             _selectedExercises = State(initialValue: Set(sampleExercises))
         }
     }

    var body: some View {
        
        NavigationStack {
            List {

                Picker("Select new or saved workout", selection: $selectedType) {
                    ForEach(newOrSaved, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color("Background"))
                
                if selectedType == "Saved" {
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .font(.headline)
                    
                    Section("Select Workout") {
                        Picker("Select Workout", selection: $selectedWorkout) {
                            ForEach(workoutTemplates) { workoutTemplate in
                                Text(workoutTemplate.title).tag(Optional(workoutTemplate))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .font(.headline)

                } else {
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .font(.headline)
                        .listRowBackground(Color("Background"))
                        
                        TextField("Workout Title", text: $eventTitle)
                            .textFieldStyle(.plain)
                            .listRowBackground(Color("Background"))

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(WorkoutCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!selectedExercises.isEmpty)
                    .listRowBackground(Color("Background"))
//                 
//                    if !selectedExercises.isEmpty {
//                        Text("Category locked - remove all exercises to change")
//                            .font(.footnote)
//                            .foregroundColor(.gray)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                            .listRowBackground(Color("Background"))
//
//                    }
                    
//                    HStack {
//                       Button {
//                           showingExerciseSheet = true
//                       } label: {
//                           Text("Add")
//                               .bold()
//                               .foregroundColor(.black)
//                       }
//                       .buttonStyle(.glass)
//
//                       Spacer()
//                    
//                   }
//                   .listRowBackground(Color("Background"))
                    
                                            
                    if selectedExercises.isEmpty {
                        Text("No exercises added")
                            .foregroundColor(.gray)
                            .italic()
                            .listRowBackground(Color("Background"))

                    } else {
                        Section {
                            ForEach(Array(selectedExercises).sorted(by: { $0.name < $1.name }), id: \.id) { exercise in
                                DisclosureGroup(exercise.name) {
                                    Text("Targets will be here")
                                        .padding(.vertical, 4)
                                }
                                .bold()
                                .listRowBackground(Color("Background"))
                            }
                            .onDelete(perform: deleteExercise)
                        }
                    }
                }
            }
            .listStyle(.plain)
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
                
                ToolbarItemGroup(placement: .bottomBar) {
                
                
                    Button {
                        showingExerciseSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                
                    if !selectedExercises.isEmpty {
                        EditButton()
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.black)
                            .tint(.black)
                    }
                }
            }
            .sheet(isPresented: $showingExerciseSheet) {
                NavigationStack {
                    ExerciseSelectionView(
                        selectedExercises: $selectedExercises,
                        workoutCategory: selectedCategory
                    )
                }
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
    
        let newEvent = WorkoutEvent(
            date: date,
            title: eventTitle.isEmpty ? nil : eventTitle
        )
        
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
    
    private func deleteExercise(at offsets: IndexSet) {
        let sortedExercises = Array(selectedExercises).sorted(by: { $0.name < $1.name })
        for index in offsets {
            let exerciseToRemove = sortedExercises[index]
            selectedExercises.remove(exerciseToRemove)
        }
    }

}

#Preview {
    WorkoutSelectionView(
        defaultDate: Date(),
        sampleExercises: [
            Exercise(name: "Bench Press"),
            Exercise(name: "Squat"),
            Exercise(name: "Deadlift")
        ]
    )
}
