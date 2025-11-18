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
    @State private var tempTargetNotes: [UUID: String] = [:]
    @State private var tempNotes: [UUID: String] = [:]
    private var editingEvent: WorkoutEvent?
    
    @State private var selectedType = "New"
    let newOrSaved = ["New", "Saved"]
    
    @State private var targetType = "Simple"
    let simpleOrAdvanced = ["Simple", "Advanced"]
    
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

        var targetNotesDict: [UUID: String] = [:]
        for we in event.workoutExercises {
            targetNotesDict[we.exercise.id] = we.targetNote ?? ""
        }
        _tempTargetNotes = State(initialValue: targetNotesDict)

        var notesDict: [UUID: String] = [:]
        for we in event.workoutExercises {
            notesDict[we.exercise.id] = we.notes ?? ""
        }
        _tempNotes = State(initialValue: notesDict)
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
                                        
             
                    Section {
                        ForEach(exerciseOrder, id: \.self) { exerciseID in
                            if let exercise = selectedExercises.first(where: { $0.id == exerciseID }) {
                                DisclosureGroup {
                                    // Content inside disclosure – not bold
                                    Picker("Select target type", selection: $targetType) {
                                        ForEach(simpleOrAdvanced, id: \.self) { type in
                                            Text(type)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .listRowBackground(Color("Background"))
                                    
                                    if targetType == "Simple" {
                                        TextField("Target... '100 x 10 for 3 sets'", text: Binding(
                                            get: { tempTargetNotes[exercise.id] ?? "" },
                                            set: { tempTargetNotes[exercise.id] = $0 }
                                        ))
                                    }
                                    
                                    TextField("Notes... 'focus on form'", text: Binding(
                                            get: { tempNotes[exercise.id] ?? "" },
                                            set: { tempNotes[exercise.id] = $0 }
                                        )
                                    )
                                    .textFieldStyle(.plain)
                                    
                                } label: {
                                    Text(exercise.name)
                                        .bold()
                                }
                                .listRowBackground(Color("Background"))
                            }
                        }
                        .onMove(perform: moveExercise)
                        .onDelete(perform: deleteExercise)
                    }

                    
                    
                    HStack {
                        Button {
                            showingExerciseSheet = true
                        } label: {
                            Text("Add Exercises")
                                .bold()
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.glass)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color("Background"))
                    .listRowSeparator(.hidden)
                    
                }
            }
            .listStyle(.plain)
            .background(Color("Background"))
            .tint(.black)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkoutEvent()
                        dismiss()
                    }
                    .disabled(selectedType == "SAVED" && selectedWorkout == nil)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
//                ToolbarItem(placement: .topBarLeading) {
//                    if !selectedExercises.isEmpty {
//                        EditButton()
//                            .foregroundColor(.black)
//                            .tint(.black)
//                    }
//                }

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
        
        if let event = editingEvent {
            event.date = date
            event.title = eventTitle.isEmpty ? nil : eventTitle
            
            let existing = Set(event.workoutExercises)
            let selected = Set(selectedExercises.map { $0.id })
            
            for w in event.workoutExercises {
                if !selected.contains(w.exercise.id) {
                    context.delete(w)
                }
            }
            
            for (index, exerciseID) in exerciseOrder.enumerated() {
                guard let exercise = selectedExercises.first(where: { $0.id == exerciseID }) else { continue }
                
                if !existing.contains(where: { $0.exercise.id == exerciseID }) {
                    let newLink = WorkoutExercise(
                        notes: tempNotes[exerciseID],
                        targetNote: tempTargetNotes[exerciseID],
                        targetMode: .simple,
                        order: index,
                        workoutEvent: event,
                        exercise: exercise
                    )
                    event.workoutExercises.append(newLink)
                } else {
                    if let existingLink = event.workoutExercises.first(where: { $0.exercise.id == exerciseID }) {
                        existingLink.order = index
                        existingLink.notes = tempNotes[exerciseID]
                        existingLink.targetNote = tempTargetNotes[exerciseID]
                    }
                }
            }
            
            try? context.save()
            return
        }
        
        let newEvent = WorkoutEvent(
            date: date,
            title: eventTitle.isEmpty ? nil : eventTitle,
            order: 0
        )
        
        context.insert(newEvent)
        
        for (index, exerciseID) in exerciseOrder.enumerated() {
            if let exercise = selectedExercises.first(where: { $0.id == exerciseID }) {
                let link = WorkoutExercise(
                    notes: tempNotes[exerciseID],
                    targetNote: tempTargetNotes[exerciseID],
                    targetMode: .simple,
                    order: index,
                    workoutEvent: newEvent,
                    exercise: exercise
                )
                newEvent.workoutExercises.append(link)
            }
        }
        
        try? context.save()

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
