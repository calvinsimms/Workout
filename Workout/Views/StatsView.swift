//
//  StatsView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var selectedCategory: WorkoutCategory = .resistance
    @State private var selectedExercise: Exercise?
    @State private var showStatsSheet = false
    

    var body: some View {
        NavigationStack {
            VStack {

                // MARK: - Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(WorkoutCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - Exercise List
                List {
                    if selectedCategory == .resistance {
                        ForEach(SubCategory.allCases) { sub in
                            DisclosureGroup(sub.rawValue) {
                                ForEach(exercisesFor(subCategory: sub)) { exercise in
                                    exerciseRow(exercise)
                                }
                            }
                            .bold()
                            .listRowBackground(Color("Background"))
                        }
                    } else {
                        ForEach(exercisesFor(category: selectedCategory)) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(Color("Background"))
            .navigationTitle("Statistics")
            .sheet(isPresented: $showStatsSheet) {
                if let exercise = selectedExercise {
                    ExerciseStatsSheet(exercise: exercise)
                }
            }
        }
    }

    // MARK: - Row Builder
    private func exerciseRow(_ exercise: Exercise) -> some View {
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

    // MARK: - Filtering Helpers
    private func exercisesFor(category: WorkoutCategory) -> [Exercise] {
        exercises.filter { $0.category == category }
    }

    private func exercisesFor(subCategory: SubCategory) -> [Exercise] {
        exercises.filter { $0.subCategory == subCategory }
    }
}

//
// MARK: - Exercise Stats Sheet
//

struct ExerciseStatsSheet: View {
    @State private var showTopOnly = false

    
    var exercise: Exercise

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {

                List {

                    // MARK: - E1RM Chart
                    Section("Estimated 1RM Chart") {
                        if exercise.topE1RMHistory.isEmpty {
                            Text("No E1RM data available yet.")
                                .foregroundStyle(.gray)
                        } else {
                            Chart(exercise.topE1RMHistory) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("E1RM", point.e1rm)
                                )
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("E1RM", point.e1rm)
                                )
                            }
                            .frame(height: 200)
                        }
                    }
                    
                    HStack {
                           Text("Set History")
                           Spacer()

                           Button {
                               withAnimation(.easeInOut) {
                                   showTopOnly.toggle()
                               }
                           } label: {
                               Text(showTopOnly ? "Show All" : "Top Sets Only")
                                   .font(.caption)
                                   .bold()
                           }
                           .buttonStyle(.glass)
                       }

                   let setsToDisplay = showTopOnly
                       ? Array(exercise.topSetsByDate)
                           .sorted { $0.date > $1.date }
                       : exercise.allSets
                    
                    ForEach(setsToDisplay) { set in
                        HStack {
                            Text(set.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)

                            Spacer()

                            if exercise.topSetsByDate.contains(set) {
                                Text("TOP")
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.gray.opacity(0.15))
                                    .foregroundColor(.black)
                                    .clipShape(Capsule())
                            }

                            if let weight = set.weight {
                                Text("\(weight, format: .number) lbs")
                            }

                            if let reps = set.reps {
                                Text("x\(reps)")
                            }

                            if let rpe = set.rpe {
                                Text("RPE \(rpe, format: .number.precision(.fractionLength(1...1)))")
                            }

                            if let e1rm = set.estimated1RM {
                                Text("E1RM \(e1rm, format: .number.precision(.fractionLength(1)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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

//
// MARK: - E1RM Models
//

struct E1RMPoint: Identifiable {
    let id = UUID()
    let date: Date
    let e1rm: Double
}

extension WorkoutSet {
    var estimated1RM: Double? {
        guard let weight = weight,
              let reps = reps,
              reps > 0 else { return nil }

        return weight * (36.0 / (37.0 - Double(reps)))
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

    /// Returns only the top (highest E1RM) set for each workout day.
    var topE1RMHistory: [E1RMPoint] {
        // 1. Group sets by calendar day
        let grouped = Dictionary(grouping: allSets) { set in
            Calendar.current.startOfDay(for: set.date)
        }

        // 2. For each day, pick the set with the highest E1RM
        let topPerDay = grouped.compactMap { (_, sets) -> E1RMPoint? in
            let bestSet = sets
                .compactMap { set -> (Date, Double)? in
                    guard let value = set.estimated1RM else { return nil }
                    return (set.date, value)
                }
                .max(by: { $0.1 < $1.1 }) // highest E1RM

            guard let best = bestSet else { return nil }

            return E1RMPoint(date: best.0, e1rm: best.1)
        }

        // 3. Sort for chart
        return topPerDay.sorted(by: { $0.date < $1.date })
    }
    
    var topSetsByDate: Set<WorkoutSet> {
        var result = Set<WorkoutSet>()
        let grouped = Dictionary(grouping: allSets) { Calendar.current.startOfDay(for: $0.date) }

        for (_, sets) in grouped {
            // Pick the set with the highest E1RM
            let bestSet = sets
                .filter { $0.estimated1RM != nil }
                .max(by: { ($0.estimated1RM ?? 0) < ($1.estimated1RM ?? 0) })

            if let best = bestSet {
                result.insert(best)
            }
        }

        return result
    }
}

//
// MARK: - Preview
//

#Preview("Exercise Stats Sheet Preview") {
    // Mock WorkoutTemplate
    let template = WorkoutTemplate(
        title: "Mock Template",
        order: 0,
        category: .resistance
    )

    // Mock Exercise
    let exercise = Exercise(
        name: "Bench Press",
        category: .resistance,
        subCategory: .chest,
        isBodyweight: false
    )

    // Mock Sets
    let set1 = WorkoutSet(
        type: .resistance,
        date: Date().addingTimeInterval(-3600),
        weight: 185,
        reps: 5,
        rpe: 8.5
    )

    let set2 = WorkoutSet(
        type: .resistance,
        date: Date().addingTimeInterval(-7200),
        weight: 175,
        reps: 6,
        rpe: 8.0
    )

    // Link sets → workoutExercise → exercise
    let workoutExercise = WorkoutExercise(
        order: 0,
        workoutTemplate: template,
        exercise: exercise
    )

    workoutExercise.sets = [set1, set2]
    exercise.workoutExercises = [workoutExercise]

    return ExerciseStatsSheet(exercise: exercise)
}
