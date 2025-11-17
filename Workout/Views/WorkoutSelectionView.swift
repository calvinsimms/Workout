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
    @State private var exerciseOrder: [UUID] = []
    private var editingEvent: WorkoutEvent?
        
    @State private var selectedType = "New"
    let newOrSaved = ["New", "Saved"]
    
    init(defaultDate: Date, sampleExercises: [Exercise]? = nil) {
        _date = State(initialValue: defaultDate)

        if let sampleExercises {
            let set = Set(sampleExercises)
            _selectedExercises = State(initialValue: set)
            _exerciseOrder = State(initialValue: set.map { $0.id })
        }
    }
    
    init(fromEvent event: WorkoutEvent) {
        editingEvent = event

        _date = State(initialValue: event.date)
        _eventTitle = State(initialValue: event.title ?? "")

        let orderedExercises = event.workoutExercises.sorted(by: { $0.order < $1.order })

        let exercises = orderedExercises.map { $0.exercise }
        _selectedExercises = State(initialValue: Set(exercises))
        _exerciseOrder = State(initialValue: orderedExercises.map { $0.exercise.id })

        if let firstCategory = exercises.first?.category {
            _selectedCategory = State(initialValue: firstCategory)
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
                            ForEach(exerciseOrder, id: \.self) { exerciseID in
                                if let exercise = selectedExercises.first(where: { $0.id == exerciseID }) {
                                    DisclosureGroup(exercise.name) {
                                        Text("Targets will be here")
                                            .padding(.vertical, 4)
                                    }
                                    .bold()
                                    .listRowBackground(Color("Background"))
                                }
                            }
                            .onMove(perform: moveExercise)
                            .onDelete(perform: deleteExercise)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color("Background"))
            .tint(.black)
            .toolbar {
//                
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") { dismiss() }
//                }
//                
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
            .onChange(of: selectedExercises) {
                for exercise in selectedExercises {
                    if exerciseOrder.contains(exercise.id) == false {
                        exerciseOrder.append(exercise.id)
                    }
                }

                exerciseOrder.removeAll { id in
                    selectedExercises.contains(where: { $0.id == id }) == false
                }
            }
        }

    }
    
    private func saveWorkoutEvent() {
        // -------------------------------------------------------
        // EDITING EXISTING EVENT
        // -------------------------------------------------------
        if let event = editingEvent {
            event.date = date
            event.title = eventTitle.isEmpty ? nil : eventTitle
            
            // Current set of exercises in the event
            let existing = Set(event.workoutExercises)
            
            // New selection
            let selected = Set(selectedExercises.map { $0.id })
            
            // Delete removed exercises
            for exercise in event.workoutExercises {
                if !selected.contains(exercise.exercise.id) {
                    context.delete(exercise)
                }
            }
            
            // Add new exercises
            for (index, exerciseID) in exerciseOrder.enumerated() {
                guard let exercise = selectedExercises.first(where: { $0.id == exerciseID }) else { continue }
                
                if !existing.contains(where: { $0.exercise.id == exerciseID }) {
                    let newLink = WorkoutExercise(
                        notes: nil,
                        targetNote: nil,
                        targetMode: .simple,
                        order: index,
                        workoutEvent: event,
                        exercise: exercise
                    )
                    event.workoutExercises.append(newLink)
                } else {
                    // Update order for existing exercise
                    if let existingLink = event.workoutExercises.first(where: { $0.exercise.id == exerciseID }) {
                        existingLink.order = index
                    }
                }
            }
            
            try? context.save()
        }

    }

    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        exerciseOrder.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteExercise(at offsets: IndexSet) {
        for index in offsets {
            let id = exerciseOrder[index]
            if let exercise = selectedExercises.first(where: { $0.id == id }) {
                selectedExercises.remove(exercise)
            }
        }
        exerciseOrder.remove(atOffsets: offsets)
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
