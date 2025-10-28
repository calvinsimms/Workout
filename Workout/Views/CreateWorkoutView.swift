//
//  CreateWorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI
import SwiftData

// MARK: - WorkoutExerciseTargetsEditor
struct WorkoutExerciseTargetsEditor: View {
    @Bindable var we: WorkoutExercise

    var body: some View {
        DisclosureGroup(we.exercise.name) {
            // Target mode switch
            Picker("Targets", selection: $we.targetMode) {
                ForEach(TargetMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)

            // Simple mode: free-form note
            if we.targetMode == .simple {
                TextField("Enter target note…", text: Binding(
                    get: { we.targetNote ?? "" },
                    set: { we.targetNote = $0 }
                ))
                .textFieldStyle(.roundedBorder)
            } else {
                AdvancedTargetSetsView(we: we)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AdvancedTargetSetsView
struct AdvancedTargetSetsView: View {
    @Bindable var we: WorkoutExercise  // the parent exercise
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show each TargetSet as a simple gray box for now
            ForEach(we.targetSets.sorted(by: { $0.order < $1.order })) { target in
                HStack {
                    Text("Target Set \(target.order + 1)")
                        .font(.subheadline)
                    Spacer()
                    Button(role: .destructive) {
                        if let index = we.targetSets.firstIndex(of: target) {
                            we.targetSets.remove(at: index)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            // Button to add a new TargetSet
            Button {
                let newSet = TargetSet(order: we.targetSets.count, workoutExercise: we)
                context.insert(newSet) // ✅ ensure TargetSet is managed
                we.targetSets.append(newSet)
            } label: {
                Label("Add Set", systemImage: "plus.circle.fill")
            }
            .padding(.top, 6)
        }
    }
}

// MARK: - CreateWorkoutView
struct CreateWorkoutView: View {
    @Bindable var workout: Workout
    var isNewWorkout: Bool
    @Binding var isNavBarHidden: Bool
    var workoutCategory: WorkoutCategory
    var onSave: ((Workout) -> Void)?
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var selectedExercises: Set<Exercise>
    
    init(workout: Workout, isNewWorkout: Bool, isNavBarHidden: Binding<Bool>, workoutCategory: WorkoutCategory = .resistance, onSave: ((Workout) -> Void)? = nil) {
        self._workout = Bindable(workout)
        self.isNewWorkout = isNewWorkout
        self._isNavBarHidden = isNavBarHidden
        self.workoutCategory = workoutCategory
        self.onSave = onSave
        _selectedExercises = State(initialValue: Set(workout.workoutExercises.map { $0.exercise }))
    }
    
    var body: some View {
        Form {
            // Workout Name
            Section("Workout Name") {
                TextField("Title", text: $workout.title)
            }
            
            // Category Section
            Section(header: Text("Category")) {
                Picker("Category", selection: $workout.category) {
                    ForEach(WorkoutCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!selectedExercises.isEmpty)
                
                if !selectedExercises.isEmpty {
                    HStack {
                        Spacer()
                        Text("Category locked - remove all exercises to change")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }

            // Exercises Section
            Section("Exercises") {
                NavigationLink("Add Exercises") {
                    ExerciseSelectionView(
                        selectedExercises: $selectedExercises,
                        workoutCategory: workout.category,
                        isNavBarHidden: $isNavBarHidden
                    )
                }

                if !workout.workoutExercises.isEmpty {
                    ForEach(workout.workoutExercises.sorted(by: { $0.order < $1.order })) { we in
                        WorkoutExerciseTargetsEditor(we: we)
                    }
                } else if !selectedExercises.isEmpty {
                    Text("Targets will appear here after creating Workout Exercises.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .navigationTitle(isNewWorkout ? "New Workout" : "Edit Workout")
        
        // MARK: Toolbar
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // Clear old workout exercises
                    workout.workoutExercises.removeAll()
                    
                    // Create & insert new WorkoutExercises ✅
                    let newWorkoutExercises = Array(selectedExercises)
                        .sorted(by: { $0.name < $1.name })
                        .enumerated()
                        .map { index, exercise in
                            let we = WorkoutExercise(
                                notes: nil,
                                targetNote: nil,
                                order: index,
                                workout: workout,
                                exercise: exercise
                            )
                            context.insert(we) // ✅ important
                            return we
                        }
                    
                    workout.workoutExercises = newWorkoutExercises
                    
                    onSave?(workout)
                    dismiss()
                }
                .disabled(workout.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        
        // MARK: Nav Bar handling
        .onAppear {
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
        }
        
        // MARK: Exercise Selection Handling
        .onChange(of: selectedExercises) {
            workout.workoutExercises = selectedExercises
                .sorted(by: { $0.name < $1.name })
                .enumerated()
                .map { index, exercise in
                    let we = WorkoutExercise(
                        notes: nil,
                        targetNote: nil,
                        targetMode: .simple,
                        order: index,
                        workout: workout,
                        exercise: exercise
                    )
                    context.insert(we) // ✅ ensure inserted
                    return we
                }
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var isNavBarHidden = false

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

    workout.workoutExercises = [we1, we2]

    return CreateWorkoutView(
        workout: workout,
        isNewWorkout: true,
        isNavBarHidden: $isNavBarHidden,
        workoutCategory: .resistance
    )
}
