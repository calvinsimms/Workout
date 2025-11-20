//
//  WorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//

import SwiftUI
import SwiftData
import Combine

enum SetCategory: String, CaseIterable, Identifiable {
    case targetSet = "Target"
    case actualSet = "Actual"
    
    var id: String { rawValue }
}

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    
    var workoutEvent: WorkoutEvent?
    var workoutTemplate: WorkoutTemplate?
    
    @State private var isEditing = false
    @FocusState private var focusedField: UUID?
    @StateObject private var timerManager = TimerManager()
    @State private var showingLapTime = false
    @State private var showingLapHistory = false
    @State private var selectedSetCategory: SetCategory = .actualSet
    @State private var selectedExercise: Exercise?


    
    private var orderedExercises: Binding<[WorkoutExercise]>? {
        guard let event = workoutEvent else { return nil }
        return Binding(
            get: { event.workoutExercises.sorted { $0.order < $1.order } },
            set: { newValue in
                for (index, exercise) in newValue.enumerated() {
                    exercise.order = index
                }
                event.workoutExercises = newValue
                try? context.save()
            }
        )
    }
    
    private var currentLapNumber: Int {
        timerManager.lapTimes.count + 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if workoutEvent == nil {
                Text("No exercises added yet")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            } else {
                if let exercisesBinding = orderedExercises {
                    List {
                        ForEach(exercisesBinding, id: \.id) { $workoutExercise in
                            DisclosureGroup {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {

                                        Button("Stats") {
                                            selectedExercise = workoutExercise.exercise
                                            }
                                           .buttonStyle(.glass)
                                        
                                        Spacer()
                                        
                                        Button("Add Set") {
                                            workoutExercise.addSet()
                                        }
                                        .buttonStyle(.glass)

                                    }
                                    .padding(.bottom, 10)
                                                                        
                                    Picker("Category", selection: $selectedSetCategory) {
                                        ForEach(SetCategory.allCases) { category in
                                            Text(category.rawValue).tag(category)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .padding(.bottom, 10)
                                    

                                    if selectedSetCategory == .targetSet {
                                        SetsInputSection(workoutExercise: workoutExercise, focusedField: $focusedField, isTargetCategory: true)
                    
                                    } else {
                                        SetsInputSection(workoutExercise: workoutExercise, focusedField: $focusedField, isTargetCategory: false)
                                    }
                                    
                                    
                                    VStack(alignment: .leading, spacing: 5) {

                                        let sets = workoutExercise.sets

                                        let highestE1RM = sets.compactMap { $0.adjustedE1RM }.max() ?? 0
                                        let totalVolume = sets.reduce(0) { $0 + (($1.weight ?? 0) * Double($1.reps ?? 0)) }
                                        let totalReps = sets.reduce(0) { $0 + ($1.reps ?? 0) }

                                        let rpes = sets.compactMap { $0.rpe }
                                        let weights = sets.compactMap { $0.weight }

                                        let avgRPE = rpes.isEmpty ? nil : (rpes.reduce(0, +) / Double(rpes.count))

                                        let avgIntensity: Double = {
                                            guard let maxE1RM = sets.compactMap({ $0.adjustedE1RM }).max(),
                                                  !weights.isEmpty else { return 0 }
                                            let avgWeight = weights.reduce(0, +) / Double(weights.count)
                                            return (avgWeight / maxE1RM) * 100
                                        }()

                                        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

                                        LazyVGrid(columns: columns, alignment: .leading) {

                                            VStack(alignment: .leading) {
                                                Text("E1RM").font(.caption2).foregroundColor(.gray)
                                                Text("\(highestE1RM, specifier: "%.1f")")
                                                    .font(.subheadline).bold()
                                            }

                                            VStack(alignment: .leading) {
                                                Text("Volume").font(.caption2).foregroundColor(.gray)
                                                Text("\(totalVolume, specifier: "%.0f")")
                                                    .font(.subheadline).bold()
                                            }

                                            VStack(alignment: .leading) {
                                                Text("Reps").font(.caption2).foregroundColor(.gray)
                                                Text("\(totalReps)")
                                                    .font(.subheadline).bold()
                                            }

                                            VStack(alignment: .leading) {
                                                Text("Intensity").font(.caption2).foregroundColor(.gray)
                                                Text("\(avgIntensity, specifier: "%.1f")")
                                                    .font(.subheadline).bold()
                                            }

                                            VStack(alignment: .leading) {
                                                Text("RPE").font(.caption2).foregroundColor(.gray)
                                                Text(avgRPE == nil ? "-" : "\(avgRPE!, specifier: "%.1f")")
                                                    .font(.subheadline).bold()
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .padding(.bottom, 5)

                                    Text("Notes")
                                        .font(.headline)

                                    TextField(
                                        "Notes",
                                        text: Binding(
                                            get: { workoutExercise.notes ?? "" },
                                            set: { workoutExercise.notes = $0 }
                                        )
                                    )
                                    .textFieldStyle(.plain)
                                    .font(.subheadline)
                                    .focused($focusedField, equals: workoutExercise.id)
                                }
                            } label: {
                                HStack {
                                    Button {
                                        workoutExercise.isCompleted.toggle()
                                    } label: {
                                        Image(systemName: workoutExercise.isCompleted ? "checkmark.circle.fill" : "circle.fill")
                                            .foregroundColor(workoutExercise.isCompleted ? .black : .white)
                                            .glassEffect()
                                            .font(.title3)
                                            .scaleEffect(workoutExercise.isCompleted ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: workoutExercise.isCompleted)
                                    }
                                    .buttonStyle(.plain)

                                    Text(workoutExercise.exercise.name)
                                        .font(.system(.title3, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 5)
                            .listRowBackground(Color("Background"))
                        }
                        .onMove { src, dest in
                            var copy = exercisesBinding.wrappedValue
                            copy.move(fromOffsets: src, toOffset: dest)

                            for (i, ex) in copy.enumerated() {
                                ex.order = i
                            }

                            exercisesBinding.wrappedValue = copy
                            try? context.save()
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { exercisesBinding.wrappedValue[$0] }
                            toDelete.forEach { context.delete($0) }
                            exercisesBinding.wrappedValue.remove(atOffsets: offsets)

                            for (i, ex) in exercisesBinding.wrappedValue.enumerated() {
                                ex.order = i
                            }

                            try? context.save()
                        }
                    }
                    .listStyle(.plain)
                    .tint(.black)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 60)
                    }
                    .sheet(item: $selectedExercise) { exercise in
                        ExerciseStatsSheet(exercise: exercise)
                    }
                }
            }
        }
        .foregroundColor(.black)
        .background(Color("Background"))
        .navigationTitle(workoutEvent?.displayTitle ?? "Workout")
        .toolbar {
            
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            
            
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isEditing = true
                }
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: { showingLapHistory = true }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                
                Button(action: { showingLapTime.toggle() }) {
                    HStack(spacing: 10) {
                        if showingLapTime {
                            Text("Lap \(max(timerManager.lapTimes.count + 1, 1))")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Text(timerManager.formattedTime(timerManager.lapTime))
                                .font(.system(.headline, design: .monospaced))
                        } else {
                            Text("Total").font(.subheadline)
                                .foregroundStyle(.gray)

                            Text(timerManager.formattedTime(timerManager.elapsedTime))
                                .font(.system(.headline, design: .monospaced))
                            
                        }
                    }
                    .fixedSize()
                }
                
                if timerManager.isRunning {
                    Button(action: {
                        timerManager.lap()
                        showingLapTime = true
                    }) {
                        Image(systemName: "flag")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                    }
                } else {
                    Button(action: {
                        timerManager.reset()
                        showingLapTime = false
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                            .foregroundColor(timerManager.elapsedTime == 0 ? .gray : .black)
                    }
                    .disabled(timerManager.elapsedTime == 0)
                }
                
                Button(action: {
                    timerManager.isRunning ? timerManager.stop() : timerManager.start()
                }) {
                    Image(systemName: timerManager.isRunning ? "stop" : "play")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let event = workoutEvent {
                NavigationStack {
                    WorkoutSelectionView(fromEvent: event)
                        .navigationTitle("Edit Workout")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingLapHistory) {
            NavigationStack {
                LapHistorySheet(timerManager: timerManager)
                    .navigationTitle("Lap History")
                    .navigationBarTitleDisplayMode(.inline)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct SetsInputSection: View {
    @Bindable var workoutExercise: WorkoutExercise
    @Environment(\.modelContext) private var context
    @State private var showSetHistory = false
    @FocusState.Binding var focusedField: UUID?

    // Pass in which category we're showing
    var isTargetCategory: Bool = false

    private var sortedSets: [Binding<WorkoutSet>] {
        workoutExercise.sets.indices
            .sorted { workoutExercise.sets[$0].order < workoutExercise.sets[$1].order }
            .map { $workoutExercise.sets[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !sortedSets.isEmpty {
                Grid(alignment: .leading) {
                    // Header
                    GridRow {
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.weight) { Text("Weight").font(.headline) }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.reps) { Text("Reps").font(.headline) }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.rpe) { Text("RPE").font(.headline) }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.duration) { Text("Duration").font(.headline) }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.distance) { Text("Distance").font(.headline) }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.resistance) { Text("Resistance").font(.headline) }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.heartRate) { Text("HR").font(.headline) }
                    }

                    // Set rows
                    ForEach(sortedSets, id: \.id) { $set in
                        GridRow {
                            if set.type.relevantAttributes.contains(.weight) {
                                TextField(
                                    "Weight",
                                    value: isTargetCategory
                                        ? Binding(projectedValue: $set.targetWeight)
                                        : Binding(projectedValue: $set.weight),
                                    format: .number
                                )
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.reps) {
                                TextField(
                                    "Reps",
                                    value: isTargetCategory
                                        ? Binding(projectedValue: $set.targetReps)
                                        : Binding(projectedValue: $set.reps),
                                    format: .number
                                )
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.rpe) {
                                TextField(
                                    "RPE",
                                    value: Binding(
                                        get: { isTargetCategory ? set.targetRPE : set.rpe },
                                        set: { newValue in
                                            if let value = newValue {
                                                if isTargetCategory { set.targetRPE = min(value, 10) }
                                                else { set.rpe = min(value, 10) }
                                            } else {
                                                if isTargetCategory { set.targetRPE = nil }
                                                else { set.rpe = nil }
                                            }
                                        }
                                    ),
                                    format: .number
                                )
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.duration) {
                                TextField(
                                    "Duration",
                                    value: isTargetCategory
                                        ? Binding(projectedValue: $set.targetDuration)
                                        : Binding(projectedValue: $set.duration),
                                    format: .number
                                )
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.distance) {
                                TextField(
                                    "Distance",
                                    value: isTargetCategory
                                        ? Binding(projectedValue: $set.targetDistance)
                                        : Binding(projectedValue: $set.distance),
                                    format: .number
                                )
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.resistance) {
                                TextField(
                                    "Resistance",
                                    value: isTargetCategory
                                        ? Binding(projectedValue: $set.targetResistance)
                                        : Binding(projectedValue: $set.resistance),
                                    format: .number
                                )
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.heartRate) {
                                TextField(
                                    "HR",
                                    value: isTargetCategory
                                        ? Binding(projectedValue: $set.targetHeartRate)
                                        : Binding(projectedValue: $set.heartRate),
                                    format: .number
                                )
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: set.id)
                            }

                            Button {
                                if isTargetCategory {
                                    // Apply target values to actual
                                    set.weight = set.targetWeight
                                    set.reps = set.targetReps
                                    set.rpe = set.targetRPE
                                    set.duration = set.targetDuration
                                    set.distance = set.targetDistance
                                    set.resistance = set.targetResistance
                                    set.heartRate = set.targetHeartRate

                                    try? context.save()
                                } else {
                                    deleteSet(set)
                                }
                            } label: {
                                if isTargetCategory {
                                    let isSynced = (set.weight == set.targetWeight) &&
                                                   (set.reps == set.targetReps) &&
                                                   (set.rpe == set.targetRPE) &&
                                                   (set.duration == set.targetDuration) &&
                                                   (set.distance == set.targetDistance) &&
                                                   (set.resistance == set.targetResistance) &&
                                                   (set.heartRate == set.targetHeartRate)
                                    
                                    Image(systemName: isSynced ? "doc.on.doc.fill" : "doc.on.doc")
                                } else {
                                    Image(systemName: "trash")
                                }
                            }
                            .buttonStyle(.plain)


                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
    }
////    
//    private func addSet() {
//        let newOrder = workoutExercise.sets.count
//        let eventDate = workoutExercise.workoutEvent?.date ?? Date()
//
//        let set = WorkoutSet(type: workoutExercise.exercise.setType, date: eventDate, order: newOrder)
//        set.workoutExercise = workoutExercise
//        workoutExercise.sets.append(set)
//
//        try? context.save()
//    }
//
    private func deleteSet(_ set: WorkoutSet) {
        context.delete(set)
        workoutExercise.sets.removeAll { $0.id == set.id }

        // Keep order consistent
        let sorted = workoutExercise.sets.sorted { $0.order < $1.order }
        for (index, s) in sorted.enumerated() {
            s.order = index
        }

        try? context.save()
    }
}




@MainActor
final class TimerManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var lapTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var lapTimes: [TimeInterval] = []

    private var timer: AnyCancellable?
    private var startDate: Date?       // absolute start timestamp
    private var lapStartDate: Date?    // absolute start timestamp for current lap

    func start() {
        guard !isRunning else { return }
        isRunning = true
        let now = Date()
        startDate = startDate ?? now
        lapStartDate = lapStartDate ?? now

        // Update display 60 times per second, but calculation is based on absolute time
        timer = Timer.publish(every: 1/60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let startDate, let lapStartDate else { return }
                self.elapsedTime = Date().timeIntervalSince(startDate)
                self.lapTime = Date().timeIntervalSince(lapStartDate)
            }
    }

    func stop() {
        isRunning = false
        timer?.cancel()
    }

    func reset() {
        elapsedTime = 0
        lapTime = 0
        lapTimes.removeAll()
        startDate = nil
        lapStartDate = nil
    }

    func lap() {
        lapTimes.insert(lapTime, at: 0)
        lapStartDate = Date()  // reset lap start timestamp
        lapTime = 0
    }

    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time * 100).truncatingRemainder(dividingBy: 100))
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}


struct LapHistorySheet: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        VStack {
            if timerManager.lapTimes.isEmpty {
                Text("No laps recorded")
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(Array(timerManager.lapTimes.enumerated()), id: \.offset) { index, time in
                        HStack {
                            Text("Lap \(timerManager.lapTimes.count - index)")
                                .font(.system(.subheadline))
                                .foregroundColor(.gray)
                            Spacer()
                            Text(timerManager.formattedTime(time))
                                .font(.system(.headline, design: .monospaced))
                        }
                    }
                    .listRowBackground(Color("Background"))
                }
                .listStyle(.plain)
            }
            Spacer()
        }
        .background(Color("Background"))
    }
}

// MARK: - Preview

#Preview {

    let squat = Exercise(
        name: "Barbell Squat",
        category: .resistance,
        subCategory: .legs
    )

    let bench = Exercise(
        name: "Bench Press",
        category: .resistance,
        subCategory: .chest
    )

    let event = WorkoutEvent(
        date: .now,
        title: "Demo Workout"
    )

    // Sample WorkoutExercises
    let squatExercise = WorkoutExercise(
        notes: "Keep chest up",
        order: 0,
        workoutEvent: event,
        exercise: squat
    )

    squatExercise.sets = [
        WorkoutSet(type: squat.setType, weight: 225, reps: 5, order: 0),
        WorkoutSet(type: squat.setType, weight: 225, reps: 5, order: 1),
        WorkoutSet(type: squat.setType, weight: 225, reps: 5, order: 2)
    ]

    let benchExercise = WorkoutExercise(
        order: 1,
        workoutEvent: event,
        exercise: bench
    )

    benchExercise.sets = [
        WorkoutSet(type: bench.setType, weight: 135, reps: 8, order: 0),
        WorkoutSet(type: bench.setType, weight: 135, reps: 8, order: 1)
    ]

    event.workoutExercises = [squatExercise, benchExercise]

    return WorkoutView(workoutEvent: event)
        .modelContainer(for: [
            Exercise.self,
            WorkoutEvent.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            WorkoutTemplate.self
        ])
}
