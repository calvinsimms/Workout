//
//  WorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//

import SwiftUI
import SwiftData
import Combine

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    
    var workoutEvent: WorkoutEvent?
    var workoutTemplate: WorkoutTemplate?

    @State private var isEditing = false
    @StateObject private var timerManager = TimerManager()
    @State private var showingLapTime = false
    @State private var showingLapHistory = false

    @State private var orderedExercises: [WorkoutExercise] = []

    private var currentLapNumber: Int {
        timerManager.lapTimes.count + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if workoutEvent != nil {
                if orderedExercises.isEmpty {
                    Text("No exercises added yet")
                        .foregroundColor(.gray)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    Spacer()
                } else {
                    exerciseList($orderedExercises, context: context)
                }

            } else if workoutTemplate != nil {
                // Template support coming later
                Text("Template mode not implemented yet")
                    .italic()
                    .padding()
                Spacer()
            }
        }
        .onAppear {
            if let event = workoutEvent {
                orderedExercises = event.workoutExercises.sorted { $0.order < $1.order }
            }
        }
        .foregroundColor(.black)
        .background(Color("Background"))
        .navigationTitle(workoutEvent?.displayTitle ?? "Workout")
        .toolbar {
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
                                .font(.headline)
                            Text(timerManager.formattedTime(timerManager.lapTime))
                                .font(.system(.headline, design: .monospaced))
                        } else {
                            Text("Total").font(.headline)
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
        .navigationDestination(isPresented: $isEditing) {
            if let event = workoutEvent {
                WorkoutSelectionView(fromEvent: event)
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

@ViewBuilder
private func exerciseList(
    _ exercises: Binding<[WorkoutExercise]>,
    context: ModelContext
) -> some View {

    List {
        ForEach(exercises.wrappedValue, id: \.id) { workoutExercise in
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Targets")
                        .font(.headline)
                        .padding(.bottom, 10)

                    TextField(
                        "Targets",
                        text: Binding(
                            get: { workoutExercise.targetNote ?? "" },
                            set: { workoutExercise.targetNote = $0 }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .padding(.bottom, 10)

                    SetsInputSection(workoutExercise: workoutExercise)
                    
                    Text("Notes")
                        .font(.headline)
                        .padding(.vertical, 10)

                    TextField(
                        "Notes",
                        text: Binding(
                            get: { workoutExercise.notes ?? "" },
                            set: { workoutExercise.notes = $0 }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                }
            } label: {
                HStack {
                    Button {
                        workoutExercise.isCompleted.toggle()
                    } label: {
                        Image(systemName: workoutExercise.isCompleted
                              ? "checkmark.circle.fill"
                              : "circle.fill")
                            .foregroundColor(workoutExercise.isCompleted ? .black : .white)
                            .glassEffect()
                            .font(.title3)
                            .scaleEffect(workoutExercise.isCompleted ? 1.1 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.6),
                                       value: workoutExercise.isCompleted)
                    }
                    .buttonStyle(.plain)

                    Text(workoutExercise.exercise.name)
                        .font(.system(.title3, weight: .semibold))
                }
            }
            .padding(.vertical, 5)
            .listRowBackground(Color("Background"))
        }
        .onMove { source, destination in
            moveExercise(exercises: exercises, from: source, to: destination, context: context)
        }
        .onDelete { offsets in
            deleteExercise(exercises: exercises, offsets: offsets, context: context)
        }
    }
    .listStyle(.plain)
    .tint(.black)
}


private func moveExercise(
    exercises: Binding<[WorkoutExercise]>,
    from source: IndexSet,
    to destination: Int,
    context: ModelContext
) {
    exercises.wrappedValue.move(fromOffsets: source, toOffset: destination)

    // rewrite all order values to match new positions
    for (index, exercise) in exercises.wrappedValue.enumerated() {
        exercise.order = index
    }

    try? context.save()
}

private func deleteExercise(
    exercises: Binding<[WorkoutExercise]>,
    offsets: IndexSet,
    context: ModelContext
) {
    let toDelete = offsets.map { exercises.wrappedValue[$0] }

    // remove from list source first
    exercises.wrappedValue.remove(atOffsets: offsets)

    // delete from SwiftData
    for ex in toDelete {
        context.delete(ex)
    }

    // reassign orders
    for (index, exercise) in exercises.wrappedValue.enumerated() {
        exercise.order = index
    }

    try? context.save()
}

// MARK: - SetsInputSection

struct SetsInputSection: View {
    @Bindable var workoutExercise: WorkoutExercise
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Sets")
                    .font(.headline)
                Spacer()
                Button(action: addSet) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.glass)
            }

            ForEach($workoutExercise.sets.sorted(by: { $0.order.wrappedValue < $1.order.wrappedValue })) { $set in
                setRow(setBinding: $set)
                    .padding(.vertical, 4)
            }
        
        }
    }

    // MARK: - Add new set
    private func addSet() {
        let newOrder = workoutExercise.sets.count
        let eventDate = workoutExercise.workoutEvent?.date ?? Date()

        let set = WorkoutSet(
            type: workoutExercise.exercise.setType,
            date: eventDate,
            order: newOrder
        )

        
        set.workoutExercise = workoutExercise

        
        workoutExercise.sets.append(set)
        

        try? context.save()
    }



    
    private func deleteSet(_ set: WorkoutSet) {

        guard let index = workoutExercise.sets.firstIndex(where: { $0.id == set.id }) else { return }

        // 1. Remove from model
        workoutExercise.sets.remove(at: index)

        // 2. Delete object from SwiftData
        context.delete(set)

        // 3. Reorder remaining sets
        for (i, s) in workoutExercise.sets.enumerated() {
            s.order = i
        }

        try? context.save()
    }


    @ViewBuilder
    private func setRow(setBinding: Binding<WorkoutSet>) -> some View {
        let set = setBinding.wrappedValue
        HStack {
            
            if set.type.relevantAttributes.contains(.weight) {
                VStack(alignment: .leading) {
                    TextField("Weight", value: setBinding.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                }
            }

            if set.type.relevantAttributes.contains(.reps) {
                VStack(alignment: .leading) {
                    TextField("Reps", value: setBinding.reps, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                }
            }

            if set.type.relevantAttributes.contains(.rpe) {
                VStack(alignment: .leading) {
                    TextField("RPE", value: setBinding.rpe, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .onChange(of: set.rpe) { oldValue, newValue in
                            let clamped = min(max(newValue ?? 0, 0), 10)
                            setBinding.rpe.wrappedValue = clamped
                        }
                }
            }

            if set.type.relevantAttributes.contains(.duration) {
                VStack(alignment: .leading) {
                    TextField("Duration (sec)", value: setBinding.duration, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                }
            }

            if set.type.relevantAttributes.contains(.distance) {
                VStack(alignment: .leading) {
                    TextField("Distance", value: setBinding.distance, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                }
            }

            if set.type.relevantAttributes.contains(.resistance) {
                VStack(alignment: .leading) {
                    TextField("Resistance", value: setBinding.resistance, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                }
            }

            if set.type.relevantAttributes.contains(.heartRate) {
                VStack(alignment: .leading) {
                    TextField("HR", value: setBinding.heartRate, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                }
            }
            
            Button {
                deleteSet(set)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
    }

}

@MainActor
final class TimerManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var lapTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var lapTimes: [TimeInterval] = []

    private var timer: AnyCancellable?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer
            .publish(every: 1/60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsedTime += 1/60
                self.lapTime += 1/60
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
    }

    func lap() {
        lapTimes.insert(lapTime, at: 0)
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
    // Sample Exercises
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

    // Sample Workout Event
    let event = WorkoutEvent(
        date: .now,
        title: "Demo Workout"
    )

    // Sample WorkoutExercises
    let squatExercise = WorkoutExercise(
        notes: "Keep chest up",
        targetNote: "3 x 5 @ 80%",
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

    // Assign exercises to event
    event.workoutExercises = [squatExercise, benchExercise]

    // PREVIEW IN A MODEL CONTAINER
    return WorkoutView(workoutEvent: event)
        .modelContainer(for: [
            Exercise.self,
            WorkoutEvent.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            WorkoutTemplate.self
        ])
}
