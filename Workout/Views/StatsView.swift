//
//  StatsView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var selectedExercise: Exercise?
    @State private var showStatsSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(exercises) { exercise in
                    Button {
                        selectedExercise = exercise
                        showStatsSheet = true
                    } label: {
                        HStack {
                              Text(exercise.name)
                                  .font(.headline)

                              Spacer()
                          }
                          .frame(maxWidth: .infinity, alignment: .leading)
                          .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color("Background"))
                }
            }
            .listStyle(.plain)
            .background(Color("Background"))
            .navigationTitle("Statistics")
            .sheet(isPresented: $showStatsSheet) {
                if let exercise = selectedExercise {
                    ExerciseStatsSheet(exercise: exercise)
                }
            }
        }
    }
}

struct ExerciseStatsSheet: View {
    var exercise: Exercise

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {

                List {
                    Text("Total Sets: \(exercise.totalSetCount)")
                    
                    ForEach(exercise.allSets) { set in
                        HStack {
                            Text(set.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)

                            Spacer()

                            if let weight = set.weight {
                                Text("\(weight, format: .number) lbs")
                            }

                            if let reps = set.reps {
                                Text("x\(reps)")
                            }

                            if let rpe = set.rpe {
                                Text("RPE \(rpe, format: .number.precision(.fractionLength(1...1)))")
                            }
                        }
                    }
                }
                .listStyle(.plain)

            }
            .navigationTitle("\(exercise.name)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}



extension Exercise {
    /// Total number of WorkoutSets ever performed for this exercise
    var totalSetCount: Int {
        workoutExercises.reduce(0) { $0 + $1.sets.count }
    }

    /// All sets across all WorkoutExercises for this Exercise
    var allSets: [WorkoutSet] {
        workoutExercises.flatMap { $0.sets }
    }
}

#Preview("Exercise Stats Sheet Preview") {
    // In-memory container just to support the data models
    let container = try! ModelContainer(
        for: Exercise.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = container.mainContext

    // Create a mock exercise
    let bench = Exercise(name: "Bench Press", category: .resistance, subCategory: .chest)
    context.insert(bench)

    // Create a mock template + workoutExercise
    let temp = WorkoutTemplate(title: "Mock Template")
    context.insert(temp)
    
    let wex = WorkoutExercise(order: 1, workoutTemplate: temp, exercise: bench)
    context.insert(wex)

    // Add some mock sets
    wex.sets.append(WorkoutSet(type: .resistance, weight: 135, reps: 8, rpe: 7))
    wex.sets.append(WorkoutSet(type: .resistance, weight: 155, reps: 5, rpe: 8))
    wex.sets.append(WorkoutSet(type: .resistance, weight: 185, reps: 3, rpe: 9))

    return ExerciseStatsSheet(exercise: bench)
        .modelContainer(container)
}



