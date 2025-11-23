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
    case targetSet = "Targets"
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
    @State private var selectedExercise: Exercise?
    @State private var setCategoryForExercise: [UUID: SetCategory] = [:]
    @State private var showingSetsInfo = false
    @State private var showingCalculator = false

    
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
                                        
                                        Button {
                                             showingCalculator = true
                                         } label: {
                                             Image(systemName: "plus.forwardslash.minus")
                                                 .font(.subheadline)
                                                 .bold()
                                         }
                                         .buttonStyle(.glass)
                                         .sheet(isPresented: $showingCalculator) {
                                             NavigationStack {
                                                 CalculatorView()
                                                     .navigationTitle("Calculator")
                                                     .navigationBarTitleDisplayMode(.inline)
                                                     .presentationDetents([.medium])

                                             }
                                         }
                                        
                                        Button {
                                            selectedExercise = workoutExercise.exercise
                                        } label: {
                                            Image(systemName: "chart.bar.fill")
                                                .font(.subheadline)
                                        }
                                        .buttonStyle(.glass)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Text("Sets")
                                                .bold()

                                            Button(action: { showingSetsInfo = true }) {
                                                Image(systemName: "info.circle")
                                                    .font(.subheadline)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .alert("Sets Information", isPresented: $showingSetsInfo) {
                                            Button("Got it!", role: .cancel) {}
                                        } message: {
                                            Text("""
                                        
                                        Target Sets: Your planned goal for this workout.
                                        Actual Sets: The sets you actually performed. Only these are tracked in statistics.
                                        
                                        "Track" Column: Sets marked with the checkmark are included in statistics. For accurate data, it’s best to track only sets with an RPE of 6+, since low-effort/warmup sets can skew your results.

                                        E1RM: Highest estimated one-rep max from performed sets.
                                        Volume: Total weight lifted (weight × reps) for all sets.
                                        Reps: Sum of reps performed across all sets.
                                        Intensity: Average load relative to your max (weight / E1RM × 100).
                                        RPE: Average Rate of Perceived Exertion. Reflects how hard each set felt (1–10 scale).
                                        
                                        Notes: Optional field for extra observations.
                                        
                                        """)
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Add Set") {
                                            withAnimation(.none) {
                                                workoutExercise.addSet()
                                            }
                                        }
                                        .buttonStyle(.glass)
                                        .font(.subheadline)

                                    }
                                    
                                    Picker("Category",
                                           selection: Binding(
                                                get: { setCategoryForExercise[workoutExercise.id] ?? .actualSet },
                                                set: { newValue in
                                                    setCategoryForExercise[workoutExercise.id] = newValue
                                                }
                                           )
                                    ) {
                                        ForEach(SetCategory.allCases) { category in
                                            Text(category.rawValue).tag(category)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    

                                    let selectedCategory = setCategoryForExercise[workoutExercise.id] ?? .actualSet

                                    if selectedCategory == .targetSet {
                                        SetsInputSection(
                                            workoutExercise: workoutExercise,
                                            focusedField: $focusedField,
                                            isTargetCategory: true
                                        )
                                    } else {
                                        SetsInputSection(
                                            workoutExercise: workoutExercise,
                                            focusedField: $focusedField,
                                            isTargetCategory: false
                                        )
                                    }
                                    
                                    
                                    VStack(alignment: .leading, spacing: 5) {

                                        let sets = workoutExercise.sets

                                        let highestE1RM = sets.compactMap { $0.adjustedE1RM }.max() ?? 0
                                        let totalVolume = sets.reduce(0) { $0 + (($1.weight ?? 0) * Double($1.reps ?? 0)) }
                                        let totalReps = sets.reduce(0) { $0 + ($1.reps ?? 0) }

                                        let rpes = sets.compactMap { $0.rpe }

                                        let avgRPE = rpes.isEmpty ? nil : (rpes.reduce(0, +) / Double(rpes.count))

                                        let avgIntensity: Double = {
                                            let validSets = sets.filter {
                                                $0.weight != nil &&
                                                $0.adjustedE1RM != nil
                                            }
                                            
                                            guard !validSets.isEmpty else { return 0 }
                                            
                                            let maxE1RM = validSets.compactMap { $0.adjustedE1RM }.max() ?? 0
                                            guard maxE1RM > 0 else { return 0 }
                                            
                                            let avgWeight = validSets.compactMap { $0.weight! }.reduce(0, +) / Double(validSets.count)
                                            
                                            return (avgWeight / maxE1RM) * 100
                                        }()

                                        HStack {

                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("E1RM").font(.caption2).foregroundColor(.gray.opacity(0.6))
                                                Text("\(highestE1RM, specifier: "%.1f")")
                                                    .font(.subheadline).bold()
                                            }
                                            
                                            Spacer()

                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("Volume").font(.caption2).foregroundColor(.gray.opacity(0.6))
                                                Text("\(totalVolume, specifier: "%.0f")")
                                                    .font(.subheadline).bold()
                                            }
                                            
                                            Spacer()

                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("Reps").font(.caption2).foregroundColor(.gray.opacity(0.6))
                                                Text("\(totalReps)")
                                                    .font(.subheadline).bold()
                                            }
                                            
                                            Spacer()

                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("Intensity").font(.caption2).foregroundColor(.gray.opacity(0.6))
                                                Text("\(avgIntensity, specifier: "%.1f")")
                                                    .font(.subheadline).bold()
                                            }
                                            
                                            Spacer()

                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("RPE").font(.caption2).foregroundColor(.gray.opacity(0.6))
                                                Text(avgRPE == nil ? "-" : "\(avgRPE!, specifier: "%.1f")")
                                                    .font(.subheadline).bold()
                                            }
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(16)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Notes")
                                            .font(.subheadline).bold()


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
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(16)
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
                    .listStyle(GroupedListStyle())
                    .scrollContentBackground(.hidden)
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
    @State private var setPendingDelete: WorkoutSet?
    @State private var showRPEInfo = false
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
            
            if workoutExercise.sets.isEmpty {
                     // Show empty state instead of grid
                     HStack {
                         Text("No sets yet - tap “Add Set” to begin.")
                             .foregroundColor(.gray.opacity(0.6))
                             .italic()
                             .font(.caption)
                         Spacer()
                     }
                     .frame(maxWidth: .infinity)
//                     .padding(16)
//                     .background(Color.gray.opacity(0.1))
//                     .cornerRadius(16)
                
            } else {
                Grid(alignment: .leading) {
                    // Headers
                    GridRow {
                        Text("Track").font(.subheadline).bold()
                        
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.weight) { Text("Weight")                                              .font(.subheadline).bold() }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.reps) { Text("Reps")                                                    .font(.subheadline).bold() }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.rpe) {
                            HStack(spacing: 4) {
                                Text("RPE").font(.subheadline).bold()
                                Button(action: {
                                    showRPEInfo = true
                                }) {
                                    Image(systemName: "info.circle")
                                        .font(.subheadline)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.duration) { Text("Duration")                                                    .font(.subheadline).bold() }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.distance) { Text("Distance")                                                    .font(.subheadline).bold() }
//                        if workoutExercise.exercise.setType.relevantAttributes.contains(.resistance) { Text("Resistance")                                                    .font(.subheadline).bold() }
                        if workoutExercise.exercise.setType.relevantAttributes.contains(.heartRate) { Text("Heart Rate")                                                    .font(.subheadline).bold() }
                    }
                    
                    // Set rows
                    ForEach(sortedSets, id: \.id) { $set in
                        GridRow {
                            
                            Button(action: {
                                // Toggle tracked state
                                set.isTracked.toggle()
                                try? context.save()
                            }) {
                                Image(systemName: set.isTracked ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(set.isTracked ? .black : .gray.opacity(0.6))
                                    .font(.subheadline)
                            }
                            .buttonStyle(.plain)
                            
                            
                            if set.type.relevantAttributes.contains(.weight) {
                                TextField(
                                    "lbs",
                                    value: isTargetCategory
                                    ? Binding(projectedValue: $set.targetWeight)
                                    : Binding(projectedValue: $set.weight),
                                    format: .number
                                )
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.reps) {
                                TextField(
                                    "0",
                                    value: isTargetCategory
                                    ? Binding(projectedValue: $set.targetReps)
                                    : Binding(projectedValue: $set.reps),
                                    format: .number
                                )
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.rpe) {
                                TextField(
                                    "1 - 10",
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
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.duration) {
                                TextField(
                                    "00:00:00",
                                    value: isTargetCategory
                                    ? Binding(projectedValue: $set.targetDuration)
                                    : Binding(projectedValue: $set.duration),
                                    format: .number
                                )
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: set.id)
                            }
                            if set.type.relevantAttributes.contains(.distance) {
                                TextField(
                                    "kms",
                                    value: isTargetCategory
                                    ? Binding(projectedValue: $set.targetDistance)
                                    : Binding(projectedValue: $set.distance),
                                    format: .number
                                )
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: set.id)
                            }
//                                if set.type.relevantAttributes.contains(.resistance) {
//                                    TextField(
//                                        "Resistance",
//                                        value: isTargetCategory
//                                        ? Binding(projectedValue: $set.targetResistance)
//                                        : Binding(projectedValue: $set.resistance),
//                                        format: .number
//                                    )
//                                    .keyboardType(.decimalPad)
//                                    .textFieldStyle(.plain)
//                                    .focused($focusedField, equals: set.id)
//                                }
                            if set.type.relevantAttributes.contains(.heartRate) {
                                TextField(
                                    "BPM",
                                    value: isTargetCategory
                                    ? Binding(projectedValue: $set.targetHeartRate)
                                    : Binding(projectedValue: $set.heartRate),
                                    format: .number
                                )
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: set.id)
                            }
                            
                            Button {
                                if isTargetCategory {
                                    set.weight = set.targetWeight
                                    set.reps = set.targetReps
                                    set.rpe = set.targetRPE
                                    set.duration = set.targetDuration
                                    set.distance = set.targetDistance
                                    set.resistance = set.targetResistance
                                    set.heartRate = set.targetHeartRate
                                    
                                    try? context.save()
                                } else {
                                    setPendingDelete = set
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
                                    
                                    Image(systemName: isSynced ? "arrow.right.circle.fill" : "arrow.right.circle")
                                    
                                } else {
                                    Image(systemName: "trash")
                                }
                            }
                            .frame(height: 10)
                            .buttonStyle(.plain)
                        }
                    }
                }
                .alert("RPE Info", isPresented: $showRPEInfo) {
                    Button("Got it!", role: .cancel) { }
                } message: {
                    Text("""
                        
                        RPE (Rate of Perceived Exertion) is a scale from 1 to 10 used to measure the difficulty of a set in resistance training.

                        1: Could do 20+ reps  
                        2: Could do many more reps  
                        3: Could do 10+ more reps  
                        4: Could do 8–10 more reps  
                        5: 5–7 reps left in the tank  
                        6: 3–4 reps remaining  
                        7: 2–3 reps remaining  
                        8: 1–2 reps left  
                        9: Could maybe squeeze out 1 more rep or use more weight 
                        10: Cannot perform another rep or use more weight 

                        Use this scale to self-regulate intensity, avoid overtraining or undertraining, and track progress over time.
                        """)
                }
            }
        }
        .alert("Delete Set?", isPresented: Binding(
            get: { setPendingDelete != nil },
            set: { if !$0 { setPendingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let setToDelete = setPendingDelete {
                    deleteSet(setToDelete)
                }
                setPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                setPendingDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this set?")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

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

#Preview {
    // Create a ModelContainer
    let container = try! ModelContainer(
        for: WorkoutTemplate.self,
             Exercise.self,
             WorkoutEvent.self,
             WorkoutExercise.self,
             WorkoutSet.self
    )

    // Sample Exercise
    let sampleExercise = Exercise(
        name: "Bench Press",
        category: .resistance,
        subCategory: .chest
    )

    // Sample WorkoutEvent
    let workoutEvent = WorkoutEvent(date: .now, title: "Sample Workout")

    // Sample WorkoutExercise
    let workoutExercise = WorkoutExercise(
        workoutEvent: workoutEvent,
        exercise: sampleExercise
    )

    // Sample WorkoutSet
    let sampleSet = WorkoutSet(
        type: sampleExercise.setType,
        date: .now,
        weight: 135,
        reps: 8,
        rpe: 7,
        order: 0
    )

    // Attach set and exercise
    workoutExercise.sets = [sampleSet]
    workoutEvent.workoutExercises = [workoutExercise]

    // Return the view
    return WorkoutView(workoutEvent: workoutEvent, workoutTemplate: nil)
        .modelContainer(container)
}
