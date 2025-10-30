//
//  CreateWorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI
import SwiftData

// MARK: - Helper View for Optional Number Fields
struct OptionalNumberField<T: LosslessStringConvertible & Numeric>: View {
    let label: String
    @Binding var value: T?
    var isDecimal: Bool = true

    var body: some View {
        TextField(label, text: Binding(
            get: { value.map(String.init) ?? "" },
            set: { newValue in
                if newValue.isEmpty {
                    value = nil
                } else if let v = T(newValue) {
                    value = v
                }
            }
        ))
        .textFieldStyle(.plain)
        .keyboardType(isDecimal ? .decimalPad : .numberPad)
        .frame(width: 70)
    }
}

// MARK: - Target Attribute Field Switch
@ViewBuilder
func attributeField(for attribute: WorkoutAttribute, target: Binding<TargetSet>) -> some View {
    switch attribute {
    case .weight:
        OptionalNumberField(label: "Weight", value: target.weight, isDecimal: true)
    case .reps:
        OptionalNumberField(label: "Reps", value: target.reps, isDecimal: false)
    case .rpe:
        OptionalNumberField(label: "RPE", value: target.rpe, isDecimal: true)
    case .duration:
        OptionalNumberField(label: "Duration", value: target.duration, isDecimal: true)
    case .distance:
        OptionalNumberField(label: "Distance", value: target.distance, isDecimal: true)
    case .resistance:
        OptionalNumberField(label: "Resistance", value: target.resistance, isDecimal: true)
    case .heartRate:
        OptionalNumberField(label: "Heart Rate", value: target.heartRate, isDecimal: false)
    }
}

// MARK: - Advanced Target Sets
struct AdvancedTargetSetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var we: WorkoutExercise

    var body: some View {
        let sortedSets = we.targetSets.sorted(by: { $0.order < $1.order })

        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, target in
                HStack(alignment: .center, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .frame(width: 24)

                    ForEach(we.exercise.setType.relevantAttributes, id: \.self) { attribute in
                        attributeField(for: attribute, target: Binding(
                            get: {
                                target
                            },
                            set: { updated in
                                if let i = we.targetSets.firstIndex(where: { $0.id == target.id }) {
                                    we.targetSets[i] = updated
                                }
                            }
                        ))
                    }

                    Spacer()

                    Button(role: .destructive) {
                        modelContext.delete(target)

                        // Remove from relationship array
                        if let index = we.targetSets.firstIndex(of: target) {
                            we.targetSets.remove(at: index)
                        }

                        // Reorder remaining sets
                        for (i, set) in we.targetSets.sorted(by: { $0.order < $1.order }).enumerated() {
                            set.order = i
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .padding(5)
                    .background(Color("Button").opacity(0.9))
                    .cornerRadius(30)
                    .shadow(radius: 2)
                    .buttonStyle(.plain)
                    .padding(.trailing, 2)
                }
            }

            HStack {
                Spacer()
                
                Button {
                    let newSet = TargetSet(order: we.targetSets.count, workoutExercise: we)

                    // ✅ Only insert if workout is already persisted
                    if we.workout?.persistentModelID != nil {
                        modelContext.insert(newSet)
                    }

                    we.targetSets.append(newSet)
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .labelStyle(.titleAndIcon)
                .padding(6)
                .background(Color("Button").opacity(0.9))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                Spacer()
            }
        }
        .padding(.bottom, 5)
    }
}

// MARK: - Workout Exercise Targets Editor
struct WorkoutExerciseTargetsEditor: View {
    @Bindable var we: WorkoutExercise

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Targets", selection: $we.targetMode) {
                    ForEach(TargetMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)

                if we.targetMode == .simple {
                    TextField("Enter target note…", text: Binding(
                        get: { we.targetNote ?? "" },
                        set: { we.targetNote = $0 }
                    ))
                    .textFieldStyle(.plain)
                } else {
                    AdvancedTargetSetsView(we: we)
                }
            }
            .padding(.top, 4)
        } label: {
            Text(we.exercise.name)
                .font(.title3)
                .bold()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Main Create Workout View
struct CreateWorkoutView: View {
    @Bindable var workout: Workout
    var isNewWorkout: Bool
    @Binding var isNavBarHidden: Bool
    var workoutCategory: WorkoutCategory
    var onSave: ((Workout) -> Void)?

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context

    @State private var selectedExercises: Set<Exercise>
    @State private var didSave = false // ✅ Track if user saved

    init(workout: Workout, isNewWorkout: Bool, isNavBarHidden: Binding<Bool>, workoutCategory: WorkoutCategory = .resistance, onSave: ((Workout) -> Void)? = nil) {
        self._workout = Bindable(workout)
        self.isNewWorkout = isNewWorkout
        self._isNavBarHidden = isNavBarHidden
        self.workoutCategory = workoutCategory
        self.onSave = onSave
        _selectedExercises = State(initialValue: Set(workout.workoutExercises.map { $0.exercise }))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Workout Name Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("WORKOUT NAME")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Title", text: $workout.title)
                        .textFieldStyle(.plain)
                }

                Divider()

                // Category Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("CATERGORY")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Category", selection: $workout.category) {
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
                }

                Divider()

                // Exercises Section
                VStack(alignment: .leading) {
                    Text("EXERCISES")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    NavigationLink {
                        ExerciseSelectionView(
                            selectedExercises: $selectedExercises,
                            workoutCategory: workout.category,
                            isNavBarHidden: $isNavBarHidden
                        )
                    } label: {
                        Label("Add Exercises", systemImage: "plus.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .padding(.vertical, 5)
                    }
                    
                    Divider()
                        
                    if !workout.workoutExercises.isEmpty {
                        VStack() {
                            ForEach(workout.workoutExercises.sorted(by: { $0.order < $1.order })) { we in
                                WorkoutExerciseTargetsEditor(we: we)

                                if we.id != workout.workoutExercises.sorted(by: { $0.order < $1.order }).last?.id {
                                    Divider()
                                }
                            }
                        }
                    } else if !selectedExercises.isEmpty {
                        Text("Targets will appear here after creating Workout Exercises.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color("Background"))
        .tint(.black)

        .navigationTitle(isNewWorkout ? "New Workout" : "Edit Workout")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    didSave = true
                    for oldWE in workout.workoutExercises {
                        context.delete(oldWE)
                    }

                    let newWorkoutExercises = Array(selectedExercises)
                        .sorted(by: { $0.name < $1.name })
                        .enumerated()
                        .map { index, exercise in
                            WorkoutExercise(
                                notes: nil,
                                targetNote: nil,
                                order: index,
                                workout: workout,
                                exercise: exercise
                            )
                        }

                    workout.workoutExercises = newWorkoutExercises
                    onSave?(workout)
                    dismiss()
                }
                .disabled(workout.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if isNewWorkout {
                context.insert(workout)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarHidden = true
                }
            }
        }
        .onDisappear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isNavBarHidden = false
            }

            if isNewWorkout && !didSave {
                context.delete(workout)
                try? context.save()
            }
        }
        .onChange(of: selectedExercises) {
            for oldWE in workout.workoutExercises {
                context.delete(oldWE)
            }

            workout.workoutExercises = selectedExercises
                .sorted(by: { $0.name < $1.name })
                .enumerated()
                .map { index, exercise in
                    WorkoutExercise(
                        notes: nil,
                        targetNote: nil,
                        targetMode: .simple,
                        order: index,
                        workout: workout,
                        exercise: exercise
                    )
                }
        }
    }
}

#Preview {
    @Previewable @State var isNavBarHidden = false

    // Seed data so the UI renders immediately
    let workout = Workout(title: "Example", category: .resistance)


    
    let bench = Exercise(name: "Bench Press", category: .resistance, subCategory: .chest)
    let squat = Exercise(name: "Back Squat", category: .resistance, subCategory: .legs)

    let we1 = WorkoutExercise(
        notes: "Elbows tucked",
        targetNote: "3×10 @ 135 lbs",
        targetMode: .simple,
        order: 0,
        workout: workout,
        exercise: bench
    )

    let we2 = WorkoutExercise(
        notes: nil,
        targetNote: nil,
        targetMode: .advanced,
        order: 1,
        workout: workout,
        exercise: squat
    )
    

    
    
//    let run = Exercise(name: "Run", category: .cardio)
//    let bike = Exercise(name: "Bike", category: .cardio)
//    
//    let we1 = WorkoutExercise(
//        notes: "Elbows tucked",
//        targetNote: "3×10 @ 135 lbs",
//        targetMode: .simple,
//        order: 0,
//        workout: workout,
//        exercise: run
//    )
//
//    let we2 = WorkoutExercise(
//        notes: "Elbows tucked",
//        targetNote: "3×10 @ 135 lbs",
//        targetMode: .advanced,
//        order: 1,
//        workout: workout,
//        exercise: bike
//    )
    
    
    
//    let pushup = Exercise(name: "Pushup", category: .resistance, isBodyweight: true)
//    let pullup = Exercise(name: "Pullup", category: .resistance, isBodyweight: true)
//
//    let we1 = WorkoutExercise(
//        notes: "Elbows tucked",
//        targetNote: "3×10 @ 135 lbs",
//        targetMode: .simple,
//        order: 0,
//        workout: workout,
//        exercise: pushup
//    )
//
//    let we2 = WorkoutExercise(
//        notes: nil,
//        targetNote: nil,
//        targetMode: .advanced,
//        order: 1,
//        workout: workout,
//        exercise: pullup
//    )

   
    
    workout.workoutExercises = [we1, we2]

    return CreateWorkoutView(
        workout: workout,
        isNewWorkout: true,
        isNavBarHidden: $isNavBarHidden,
        workoutCategory: .resistance
    )
}

