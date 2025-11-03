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
                            get: { target },
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

                        if let index = we.targetSets.firstIndex(of: target) {
                            we.targetSets.remove(at: index)
                        }

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

                    if we.workoutTemplate?.persistentModelID != nil {
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
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Main Create Workout View
struct CreateWorkoutView: View {
    @Bindable var workoutTemplate: WorkoutTemplate
    var isNewWorkout: Bool
    var workoutCategory: WorkoutCategory
    var onSave: ((WorkoutTemplate) -> Void)?

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context

    @State private var selectedExercises: Set<Exercise>
    @State private var didSave = false

    init(workoutTemplate: WorkoutTemplate, isNewWorkout: Bool, workoutCategory: WorkoutCategory = .resistance, onSave: ((WorkoutTemplate) -> Void)? = nil) {
        self._workoutTemplate = Bindable(workoutTemplate)
        self.isNewWorkout = isNewWorkout
        self.workoutCategory = workoutCategory
        self.onSave = onSave
        _selectedExercises = State(initialValue: Set(workoutTemplate.workoutExercises.map { $0.exercise }))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Workout Name Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("WORKOUT NAME")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Title", text: $workoutTemplate.title)
                        .textFieldStyle(.plain)
                }

                Divider()

                // Category Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("CATERGORY")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Category", selection: $workoutTemplate.category) {
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
                            workoutCategory: workoutTemplate.category
                        )
                    } label: {
                        Label("Add Exercises", systemImage: "plus.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .padding(.vertical, 5)
                    }
                    
                    Divider()
                        
                    if !workoutTemplate.workoutExercises.isEmpty {
                        VStack {
                            ForEach(workoutTemplate.workoutExercises.sorted(by: { $0.order < $1.order })) { we in
                                WorkoutExerciseTargetsEditor(we: we)

                                if we.id != workoutTemplate.workoutExercises.sorted(by: { $0.order < $1.order }).last?.id {
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
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(isNewWorkout ? "New Workout" : "Edit Workout")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    didSave = true
                    for oldWE in workoutTemplate.workoutExercises {
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
                                workoutTemplate: workoutTemplate,
                                exercise: exercise
                            )
                        }

                    workoutTemplate.workoutExercises = newWorkoutExercises
                    onSave?(workoutTemplate)
                    dismiss()
                }
                .disabled(workoutTemplate.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if isNewWorkout {
                context.insert(workoutTemplate)
            }
        }
        .onDisappear {
            if isNewWorkout && !didSave {
                context.delete(workoutTemplate)
                try? context.save()
            }
        }
        .onChange(of: selectedExercises) {
            for oldWE in workoutTemplate.workoutExercises {
                context.delete(oldWE)
            }

            workoutTemplate.workoutExercises = selectedExercises
                .sorted(by: { $0.name < $1.name })
                .enumerated()
                .map { index, exercise in
                    WorkoutExercise(
                        notes: nil,
                        targetNote: nil,
                        targetMode: .simple,
                        order: index,
                        workoutTemplate: workoutTemplate,
                        exercise: exercise
                    )
                }
        }
    }
}

#Preview {
    let workoutTemplate = WorkoutTemplate(title: "Example", category: .resistance)
    
    let bench = Exercise(name: "Bench Press", category: .resistance, subCategory: .chest)
    let squat = Exercise(name: "Back Squat", category: .resistance, subCategory: .legs)

    let we1 = WorkoutExercise(
        notes: "Elbows tucked",
        targetNote: "3×10 @ 135 lbs",
        targetMode: .simple,
        order: 0,
        workoutTemplate: workoutTemplate,
        exercise: bench
    )

    let we2 = WorkoutExercise(
        notes: nil,
        targetNote: nil,
        targetMode: .advanced,
        order: 1,
        workoutTemplate: workoutTemplate,
        exercise: squat
    )

    workoutTemplate.workoutExercises = [we1, we2]

    return CreateWorkoutView(
        workoutTemplate: workoutTemplate,
        isNewWorkout: true,
        workoutCategory: .resistance
    )
}

