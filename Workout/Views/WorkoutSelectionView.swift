//
//  WorkoutSelectionView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-11.
//

import SwiftUI
import SwiftData


enum EventType: String, CaseIterable, Identifiable {
    case newWorkout = "New Workout"
    case savedWorkout = "Saved Workout"
    case measurement = "Measurements"
    
    var id: String { rawValue }
}

struct WorkoutSelectionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode
    
    @Query(sort: [SortDescriptor(\WorkoutTemplate.title)]) private var workoutTemplates: [WorkoutTemplate]
    
    @State private var selectedWorkout: WorkoutTemplate?
    @Binding var date: Date
    @State private var editableDate: Date?
    @State private var eventTitle: String = ""
    @State private var showingExerciseSheet = false
    @State private var selectedExercises: Set<Exercise> = []
    @State private var selectedCategory: WorkoutCategory = .resistance
    @State private var exerciseOrder: [UUID] = []
    @State private var tempNotes: [UUID: String] = [:]
    @State private var selectedEventType: EventType = .newWorkout
    @State private var selectedMeasurementType: MeasurementType = .weight
    @State private var measurementValue: Double = 0
    @State private var measurementValues: [MeasurementType: Double] = [:]
    
    private var editingEvent: WorkoutEvent?
    
    init(date: Binding<Date>, sampleExercises: [Exercise]? = nil) {
        self.editingEvent = nil
        _date = date

        if let sampleExercises {
            let set = Set(sampleExercises)
            _selectedExercises = State(initialValue: set)
            _exerciseOrder = State(initialValue: set.map { $0.id })
        }
    }
    
    init(fromEvent event: WorkoutEvent) {
        editingEvent = event

        _date = Binding.constant(event.date) 
        _eventTitle = State(initialValue: event.title ?? "")

        let orderedExercises = event.workoutExercises.sorted(by: { $0.order < $1.order })

        let exercises = orderedExercises.map { $0.exercise }
        _selectedExercises = State(initialValue: Set(exercises))
        _exerciseOrder = State(initialValue: orderedExercises.map { $0.exercise.id })

        if let firstCategory = exercises.first?.category {
            _selectedCategory = State(initialValue: firstCategory)
        }

        var notesDict: [UUID: String] = [:]
        for we in event.workoutExercises {
            notesDict[we.exercise.id] = we.notes ?? ""
        }
        _tempNotes = State(initialValue: notesDict)
    }
    
    var body: some View {
        
        
        
        List {
            
           Section {
                Picker("Event Type", selection: $selectedEventType) {
                    ForEach(EventType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

            }
            .listRowBackground(Color("Background"))
            
            if selectedEventType == .newWorkout {

                Section {
                    HStack {
                        Text("Workout Title")
                            .bold()
                        Spacer()
                        TextField("Enter Title", text: $eventTitle)
//                            .bold()
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker(
                        "Date",
                        selection: Binding<Date>(
                            get: { editableDate ?? date },
                            set: { newValue in
                                if editingEvent != nil {
                                    editableDate = newValue
                                } else {
                                    date = newValue
                                }
                            }
                        ),
                        displayedComponents: .date
                    )
                    .bold()
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(WorkoutCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .bold()
                    .pickerStyle(.segmented)
                    .disabled(!selectedExercises.isEmpty)
                    
                    NavigationLink {
                        ExerciseSelectionView(
                            selectedExercises: $selectedExercises,
                            workoutCategory: selectedCategory
                        )
                        .navigationTitle("Select Exercises")
                    } label: {
                        Text("Add Exercises")
                            .bold()
                        
                    }
                    
                }
                .listRowBackground(Color("Background"))
                
                ForEach(exerciseOrder, id: \.self) { exerciseID in
                    if let exercise = selectedExercises.first(where: { $0.id == exerciseID }) {
                        DisclosureGroup {
                            
                            TextField("Notes... ''100 for 3 sets of 10 reps''", text: Binding(
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
                
            } else if selectedEventType == .measurement {
                Section {
                    ForEach(MeasurementType.allCases) { type in
                        HStack {
                            Text(type.rawValue)
                                .bold()
                            Spacer()
                            TextField(
                                "Enter value",
                                text: Binding(
                                    get: {
                                        if let value = measurementValues[type] {
                                            return String(value)
                                        } else {
                                            return ""
                                        }
                                    },
                                    set: { newValue in
                                        if let doubleValue = Double(newValue) {
                                            measurementValues[type] = doubleValue
                                        } else {
                                            measurementValues[type] = nil
                                        }
                                    }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        }

                    }
                }
                .listRowBackground(Color("Background"))
            }

                
            
        }
        .listStyle(GroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveWorkoutEvent()
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            if !selectedExercises.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    EditButton()
                        .tint(.black)
                }
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
    
    private func saveWorkoutEvent() {
        
        // Handle editing an existing workout event
        if let event = editingEvent, selectedEventType != .measurement {
            event.date = editableDate ?? event.date
            event.title = eventTitle.isEmpty ? nil : eventTitle
            
            let existing = Set(event.workoutExercises)
            let selected = Set(selectedExercises.map { $0.id })
            
            // Remove exercises no longer selected
            for w in event.workoutExercises {
                if !selected.contains(w.exercise.id) {
                    context.delete(w)
                }
            }
            
            // Add/update exercises
            for (index, exerciseID) in exerciseOrder.enumerated() {
                guard let exercise = selectedExercises.first(where: { $0.id == exerciseID }) else { continue }
                
                if !existing.contains(where: { $0.exercise.id == exerciseID }) {
                    let newLink = WorkoutExercise(
                        notes: tempNotes[exerciseID],
                        order: index,
                        workoutEvent: event,
                        exercise: exercise
                    )
                    event.workoutExercises.append(newLink)
                } else {
                    if let existingLink = event.workoutExercises.first(where: { $0.exercise.id == exerciseID }) {
                        existingLink.order = index
                        existingLink.notes = tempNotes[exerciseID]
                    }
                }
            }
            
            try? context.save()
            return
        }
        
        // Handle creating a new event
        switch selectedEventType {
        case .newWorkout, .savedWorkout:
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
                        order: index,
                        workoutEvent: newEvent,
                        exercise: exercise
                    )
                    newEvent.workoutExercises.append(link)
                }
            }
            
        case .measurement:
            let newMeasurement = Measurement(
                type: selectedMeasurementType,
                value: measurementValue,
                date: date
            )
            context.insert(newMeasurement)
        }
        
        try? context.save()
        dismiss()
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
        date: .constant(Date()),
        sampleExercises: [
            Exercise(name: "Bench Press"),
            Exercise(name: "Squat"),
            Exercise(name: "Deadlift")
        ]
    )
}


