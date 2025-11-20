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
    
    let measurements = ["Chest", "Shoulders", "Arms", "Biceps", "Triceps", "Waist", "Hips", "Thighs", "Calves", "Forearms", "Neck"]
    
    let strengthFormulas = ["DOTS", "Good Lift Classic", "Good Lift Equipped", "Wilks"]

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    
                    Section(header: Text("Overall")
                    ) {
                        
                        DisclosureGroup("Body Composition") {
                            Text("Body Fat Percentage")
                            Text("Bodyweight")
                            Text("Lean Muscle Mass")
                        }
                        
                        DisclosureGroup("Bodybuilding") {
                            DisclosureGroup("Measurements"){
                                ForEach(measurements, id: \.self) { measurement in
                                    Text(measurement)
                                }
                            }
                        }
                        
                        DisclosureGroup("Powerlifting") {
                            Text("Competition Total")
                            
                            DisclosureGroup("Strength Formulas"){
                                ForEach(strengthFormulas, id: \.self) { strengthFormula in
                                    Text(strengthFormula)
                                }
                            }
                        }
                                                
                    }
                    .bold()
                    .listRowBackground(Color("Background"))
                    
                    Section(header: Text("By Exercise")
                    ) {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(WorkoutCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color("Background"))
                        
                        if selectedCategory == .resistance {
                            ForEach(SubCategory.allCases) { sub in
                                DisclosureGroup(sub.rawValue) {
                                    ForEach(exercisesFor(subCategory: sub)) { exercise in
                                        exerciseRow(exercise)
                                    }
                                }
                            }
                        } else {
                            ForEach(exercisesFor(category: selectedCategory)) { exercise in
                                exerciseRow(exercise)
                            }
                        }
                    }
                    .bold()
                    .listRowBackground(Color("Background"))
                }
                .listStyle(.plain)
            }
            .background(Color("Background"))
            .navigationTitle("Statistics")
            .sheet(item: $selectedExercise) { exercise in
                ExerciseStatsSheet(exercise: exercise)
            }
        }
    }


    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button {
            selectedExercise = exercise
        } label: {
            HStack {
                Text(exercise.name).font(.headline)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color("Background"))
    }

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

enum StatType: String, CaseIterable, Identifiable {
    case e1rm = "E1RM"
    case volume = "Volume"
    case reps = "Reps"
    case intensity = "Intensity"
    case rpe = "RPE"
    
    var id: String { rawValue }
}

enum StatRange: String, CaseIterable, Identifiable {
    case all = "All"
    case week = "Week"
    case lastMonth = "Month"
    case lastThreeMonths = "3 Months"
    case custom = "Custom"
    
    var id: String { rawValue }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ExerciseStatsSheet: View {
    @State private var showTopOnly = false
    @State private var selectedStatType: StatType = .e1rm
    @State private var selectedRange: StatRange = .all
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var selectedPoint: ChartPoint?
    @State private var workoutsToShowCount = 10
    
    var exercise: Exercise
    
    var chartData: [ChartPoint] {
        exercise.chartPoints(for: selectedStatType, in: selectedRange, customStart: customStartDate, customEnd: customEndDate)
    }
    
    var xDomain: ClosedRange<Date>? {
        if selectedRange == .all {
            return nil
        }
        let now = Date()
        let startDate: Date
        let endDate: Date
        switch selectedRange {
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            endDate = now
        case .lastMonth:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
            endDate = now
        case .lastThreeMonths:
            startDate = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
            endDate = now
        case .custom:
            startDate = customStartDate
            endDate = customEndDate
        case .all:
            return nil
        }

        if let first = chartData.first?.date, let last = chartData.last?.date, first == last {
            let paddedStart = Calendar.current.date(byAdding: .day, value: -1, to: first) ?? first
            let paddedEnd = Calendar.current.date(byAdding: .day, value: 1, to: first) ?? first
            return paddedStart...paddedEnd
        }
        return startDate...endDate
    }

    var yDomain: ClosedRange<Double>? {
        guard let minValue = chartData.map(\.value).min(),
              let maxValue = chartData.map(\.value).max() else {
            return nil
        }
        if minValue == maxValue {
            let padding = maxValue * 0.1
            return (maxValue - padding)...(maxValue + padding)
        }
        let padding = (maxValue - minValue) * 0.2
        let lower = max(minValue - padding, 0)
        let upper = maxValue + padding
        return lower...upper
    }

    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {

                List {
                    
                    Picker("Stats", selection: $selectedStatType) {
                        ForEach(StatType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if exercise.topE1RMHistory.isEmpty {
                        Text("No exercise data available yet.")
                            .foregroundStyle(.gray)
                    } else {
                        Chart(chartData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                        }
                        .frame(height: 200)
                        .chartXScale(domain: xDomain ?? ((chartData.first?.date ?? Date())...(chartData.last?.date ?? Date())))
                        .chartYScale(domain: yDomain ?? ((chartData.map(\.value).min() ?? 0)...(chartData.map(\.value).max() ?? 1)))
                        .chartOverlay { proxy in
                            GeometryReader { geo in
                                Rectangle().fill(Color.clear).contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let location = value.location
                                                if let date: Date = proxy.value(atX: location.x) {
                                                    if let nearest = chartData.min(by: { abs($0.date.timeIntervalSince1970 - date.timeIntervalSince1970) < abs($1.date.timeIntervalSince1970 - date.timeIntervalSince1970) }) {
                                                        selectedPoint = nearest
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                    selectedPoint = nil
                                                }
                                            }
                                    )
                            }
                        }
                        .overlay(alignment: .topLeading) {
                            if let selected = selectedPoint {
                                Text("\(selected.value, specifier: "%.1f")")
                                    .padding(6)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                                    .transition(.opacity)
                                    
                            }
                        }
                    }
                    
                    
                    Picker("Range", selection: $selectedRange) {
                        ForEach(StatRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedRange == .custom {
                        DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                                
    
                        DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                                

                    }
                    HStack {
                        Text("Change:")
                        
                        Spacer()
                        
                        let points = exercise.chartPoints(for: selectedStatType, in: selectedRange, customStart: customStartDate, customEnd: customEndDate)
                        if let firstValue = points.first?.value, let lastValue = points.last?.value {
                            let diff = lastValue - firstValue
                            let percent = (diff / firstValue) * 100
                            Text("\(diff >= 0 ? "+" : "")\(diff, specifier: "%.1f") (\(percent >= 0 ? "+" : "")\(percent, specifier: "%.1f")%)")
                                .foregroundColor(.black)
                        } else {
                            Text("-")
                                .foregroundColor(.gray)
                        }
                    }

                    
                    SetHistoryView(
                        allSets: exercise.allSetsByDateDescending,
                        topSets: exercise.topSetsByDate,
                        showTopOnly: $showTopOnly,
                        headerTitle: "Set History"
                    )

            
                }
                .listStyle(.plain)
            }
            .navigationTitle("\(exercise.name)")
            .navigationBarTitleDisplayMode(.inline)
            
        }
    }
}

struct SetHistoryView: View {
    let allSets: [WorkoutSet]
    let topSets: [WorkoutSet]
    @Binding var showTopOnly: Bool
    let headerTitle: String?

    var body: some View {
        Section(header: header) {
            let setsToDisplay = showTopOnly
                ? topSets
                : allSets

            ForEach(setsToDisplay) { set in
                HStack {
                    Text(set.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                    Spacer()

                    if topSets.contains(set) {
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

                    if let e1rm = set.adjustedE1RM {
                        Text("E1RM \(e1rm, format: .number.precision(.fractionLength(1)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.clear)

            }
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Text(headerTitle ?? "Set History")
                .font(.headline)
            Spacer()
            Button {
                showTopOnly.toggle()
            } label: {
                Text(showTopOnly ? "Show All" : "Top Sets Only")
                    .font(.caption)
                    .bold()
            }
            .buttonStyle(.glass)
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
    var adjustedE1RM: Double? {
           guard let weight = weight,
                 let reps = reps,
                 reps > 0 else { return nil }

           let rpeValue = rpe ?? 10
           let repsAtRPE10 = Double(reps) + (10 - rpeValue)

           let denominator = 1.0278 - 0.0278 * repsAtRPE10
           guard denominator > 0 else { return nil }

           return weight / denominator
       }
}

extension Exercise {

    var allSetsWithAdjustedE1RM: [WorkoutSet] {
           allSetsByDateDescending
       }
    
    var allSetsByDateDescending: [WorkoutSet] {
         workoutExercises
             .flatMap { $0.sets }
             .filter { $0.adjustedE1RM != nil }
             .sorted { $0.date > $1.date }
     }
    
    var totalRepsHistory: [ChartPoint] {
          let groupedByDay = Dictionary(grouping: allSetsWithAdjustedE1RM) {
              Calendar.current.startOfDay(for: $0.date)
          }

          return groupedByDay.compactMap { day, sets in
              let totalReps = sets.reduce(0) { $0 + ($1.reps ?? 0) }
              return ChartPoint(date: day, value: Double(totalReps))
          }
          .sorted { $0.date < $1.date }
      }

    var topE1RMHistory: [E1RMPoint] {
           let grouped = Dictionary(grouping: allSetsWithAdjustedE1RM) { Calendar.current.startOfDay(for: $0.date) }
           return grouped.compactMap { (_, sets) in
               guard let best = sets.max(by: { ($0.adjustedE1RM ?? 0) < ($1.adjustedE1RM ?? 0) }) else { return nil }
               return E1RMPoint(date: best.date, e1rm: best.adjustedE1RM!)
           }
           .sorted { $0.date < $1.date }
       }

    var setsSortedByDayAndE1RM: [(day: Date, sets: [WorkoutSet])] {
        let grouped = Dictionary(grouping: allSetsWithAdjustedE1RM) {
            Calendar.current.startOfDay(for: $0.date)
        }

        return grouped
            .map { day, sets in
                (
                    day: day,
                    sets: sets.sorted { ($0.adjustedE1RM ?? 0) > ($1.adjustedE1RM ?? 0) }
                )
            }
            .sorted { $0.day > $1.day }
    }

    var topSetsByDate: [WorkoutSet] {
          let grouped = Dictionary(grouping: allSetsWithAdjustedE1RM) { Calendar.current.startOfDay(for: $0.date) }
          return grouped.compactMap { (_, sets) in
              sets.max(by: { ($0.adjustedE1RM ?? 0) < ($1.adjustedE1RM ?? 0) })
          }
          .sorted { $0.date > $1.date }
      }

    var volumeHistory: [ChartPoint] {
        let grouped = Dictionary(grouping: allSetsWithAdjustedE1RM) {
            Calendar.current.startOfDay(for: $0.date)
        }

        return grouped.compactMap { day, sets in
            let volume = sets.reduce(0) { total, set in
                if let w = set.weight, let r = set.reps {
                    return total + (w * Double(r))
                }
                return total
            }
            return ChartPoint(date: day, value: volume)
        }
        .sorted { $0.date < $1.date }
    }

    var averageIntensity: [ChartPoint] {
        let groupedByDay = Dictionary(grouping: allSetsWithAdjustedE1RM) {
            Calendar.current.startOfDay(for: $0.date)
        }

        return groupedByDay.compactMap { day, sets in
            guard let maxE1RM = sets.compactMap({ $0.adjustedE1RM }).max(),
                  maxE1RM > 0 else { return nil }
            let avgWeight = sets.compactMap { $0.weight }.reduce(0, +) / Double(sets.count)
            let avgIntensity = (avgWeight / maxE1RM) * 100
            return ChartPoint(date: day, value: avgIntensity)
        }
        .sorted { $0.date < $1.date }
    }
    
    var averageRPE: [ChartPoint] {
        let groupedByDay = Dictionary(grouping: allSetsWithAdjustedE1RM) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return groupedByDay.compactMap { day, sets in
            let rpes = sets.compactMap { $0.rpe }
            guard !rpes.isEmpty else { return nil }
            let avgRPE = rpes.reduce(0, +) / Double(rpes.count)
            return ChartPoint(date: day, value: avgRPE)
        }
        .sorted { $0.date < $1.date }
    }


    
    func chartPoints(for stat: StatType, in range: StatRange, customStart: Date? = nil, customEnd: Date? = nil) -> [ChartPoint] {
        let data: [ChartPoint]
        
        switch stat {
        case .e1rm:
            data = topE1RMHistory.map { ChartPoint(date: $0.date, value: $0.e1rm) }
        case .volume: data = volumeHistory
        case .reps: data = totalRepsHistory  
        case .intensity: data = averageIntensity
        case .rpe: data = averageRPE
        }

        let now = Date()
        let startDate: Date
        let endDate: Date = range == .custom ? (customEnd ?? now) : now

        switch range {
        case .all:
            startDate = data.first?.date ?? now
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .lastMonth:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .lastThreeMonths:
            startDate = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
        case .custom:
            startDate = customStart ?? now
        }

        return data.filter { $0.date >= startDate && $0.date <= endDate }
    }


    func difference(for stat: StatType, in range: StatRange, customStart: Date? = nil, customEnd: Date? = nil) -> Double? {
        let points = chartPoints(for: stat, in: range, customStart: customStart, customEnd: customEnd).sorted { $0.date < $1.date }
        guard let first = points.first?.value, let last = points.last?.value else { return nil }
        return last - first
    }
    
}


//
// MARK: - Preview
//

#Preview {
    StatsView()
}

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

    // Mock Sets with different RPEs
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

    let set3 = WorkoutSet(
        type: .resistance,
        date: Date().addingTimeInterval(-7200),
        weight: 160,
        reps: 8,
        rpe: 7.5
    )

    // Link sets → workoutExercise → exercise
    let workoutExercise = WorkoutExercise(
        order: 0,
        workoutTemplate: template,
        exercise: exercise
    )

    workoutExercise.sets = [set1, set2, set3]
    exercise.workoutExercises = [workoutExercise]

    // Preview ExerciseStatsSheet
    return ExerciseStatsSheet(exercise: exercise)
}
