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
    @State private var notes: String = ""
    @StateObject private var timerManager = TimerManager()
    @State private var showingLapTime = false
    @State private var showingLapHistory = false
    
    var exercises: [WorkoutExercise] {
        workoutEvent?.workoutExercises.sorted(by: { $0.order < $1.order }) ?? []
    }

    private var currentLapNumber: Int {
        timerManager.lapTimes.count + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let event = workoutEvent {
                if event.workoutExercises.isEmpty {
                    Text("No exercises added yet")
                        .foregroundColor(.gray)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    Spacer()
                } else {
                    exerciseList(
                        event.workoutExercises.sorted { $0.order < $1.order },
                        context: context
                    )
                }
            } else if let template = workoutTemplate {
                if template.workoutExercises.isEmpty {
                    Text("No exercises added yet")
                        .foregroundColor(.gray)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Spacer()
                } else {
                    exerciseList(
                        template.workoutExercises.sorted { $0.order < $1.order },
                        context: context
                    )
                }
            }
        }
        .foregroundColor(.black)
        .background(Color("Background"))
        .navigationTitle(workoutEvent?.displayTitle ?? workoutTemplate?.title ?? "Workout")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isEditing = true
                }
            }

            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    showingLapHistory = true
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                
                Button(action: {
                    showingLapTime.toggle()
                }) {
                    HStack(spacing: 10) {
                        if showingLapTime {
                            Text("Lap \(max(timerManager.lapTimes.count + 1, 1))")
                                .font(.system(
                                    size: UIFont.preferredFont(forTextStyle: .headline).pointSize,
                                    weight: .regular
                                ))
                            Text(timerManager.formattedTime(timerManager.lapTime))
                                .font(.system(
                                    size: UIFont.preferredFont(forTextStyle: .headline).pointSize,
                                    weight: .regular,
                                    design: .monospaced
                                ))
                        } else {
                            Text("Total")
                                .font(.system(
                                    size: UIFont.preferredFont(forTextStyle: .headline).pointSize,
                                    weight: .regular
                                ))
                            Text(timerManager.formattedTime(timerManager.elapsedTime))
                                .font(.system(
                                    size: UIFont.preferredFont(forTextStyle: .headline).pointSize,
                                    weight: .regular,
                                    design: .monospaced
                                ))
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
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
            if let template = workoutTemplate {
                CreateWorkoutView(
                    workoutTemplate: template,
                    isNewWorkout: false
                )
            } else if let event = workoutEvent {
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
private func exerciseList(_ exercises: [WorkoutExercise], context: ModelContext) -> some View {
    List {
        ForEach(exercises, id: \.id) { workoutExercise in
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
                    
                    Divider()
                        .padding(.vertical, 10)

                    SetsInputSection(workoutExercise: workoutExercise)
                    
                    Text("Notes")
                        .font(.headline)
                        .padding(.bottom, 10)

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
                        Image(systemName: workoutExercise.isCompleted ? "checkmark.circle.fill" : "circle.fill")
                            .foregroundColor(workoutExercise.isCompleted ? .black : .white)
                            .glassEffect()
                            .font(.title3)
                            .scaleEffect(workoutExercise.isCompleted ? 1.1 : 1.0)
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.6),
                                value: workoutExercise.isCompleted
                            )
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
            moveExercise(
                exercises: exercises,
                from: source,
                to: destination,
                context: context
            )
        }
        .onDelete { offsets in
            deleteExercise(
                exercises: exercises,
                offsets: offsets,
                context: context
            )
        }
    }
    .listStyle(.plain)
    .tint(.black)
}

private func moveExercise(
    exercises: [WorkoutExercise],
    from source: IndexSet,
    to destination: Int,
    context: ModelContext
) {
    // Work on a local copy that reflects the visible order
    var mutable = exercises
    mutable.move(fromOffsets: source, toOffset: destination)

    // Reassign orders based on the new order
    for (index, exercise) in mutable.enumerated() {
        exercise.order = index
    }

    try? context.save()
}

private func deleteExercise(
    exercises: [WorkoutExercise],
    offsets: IndexSet,
    context: ModelContext
) {
    // Local copy in the same order as displayed
    var mutable = exercises

    // Objects to delete based on visible indices
    let objectsToDelete = offsets.compactMap { index -> WorkoutExercise? in
        guard index < mutable.count else { return nil }
        return mutable[index]
    }

    // Remove from local copy first (so we can rewrite order)
    mutable.remove(atOffsets: offsets)

    // Delete from persistence
    for obj in objectsToDelete {
        context.delete(obj)
    }

    // Rewrite order for remaining items
    for (index, exercise) in mutable.enumerated() {
        exercise.order = index
    }

    try? context.save()
}

// MARK: - SetsInputSection

struct SetsInputSection: View {
    @Bindable var workoutExercise: WorkoutExercise
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Sets")
                    .font(.headline)
                Spacer()
//                EditButton()
//                    .buttonStyle(.glass)
//                    .opacity(workoutExercise.sets.isEmpty ? 0 : 1)
                Button {
                    addSet()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                }
                .buttonStyle(.glass)
            }

            Divider()
                .padding(.top, 10)

            List {
                ForEach(Array(workoutExercise.sets.enumerated()), id: \.element.id) { index, set in
                    // ✅ Guard against out-of-range indices during SwiftUI updates
                    let binding = Binding<WorkoutSet>(
                        get: {
                            guard index < workoutExercise.sets.count else {
                                // Fallback so SwiftUI doesn’t crash while views are updating
                                return workoutExercise.sets.last ?? set
                            }
                            return workoutExercise.sets[index]
                        },
                        set: { newValue in
                            guard index < workoutExercise.sets.count else { return }
                            workoutExercise.sets[index] = newValue
                        }
                    )

                    HStack {
                        ForEach(set.type.relevantAttributes) { attribute in
                            attributeField(attribute: attribute, set: binding)
                        }
                    }
                    .listRowBackground(Color("Background"))
                }
                .onDelete(perform: deleteSet)
                .onMove(perform: moveSet)
            }
            .frame(height: CGFloat(workoutExercise.sets.count) * 44 + 20)
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private func attributeField(attribute: WorkoutAttribute, set: Binding<WorkoutSet>) -> some View {
        switch attribute {
        case .weight:
            TextField("Weight", value: set.weight, format: .number)
                .keyboardType(.decimalPad)
        case .reps:
            TextField("Reps", value: set.reps, format: .number)
                .keyboardType(.numberPad)
        case .rpe:
            TextField(
                "RPE",
                value: set.rpe,
                format: .number.precision(.fractionLength(0...1))
            )
            .keyboardType(.decimalPad)
        case .duration:
            TextField("Duration", value: set.duration, format: .number)
                .keyboardType(.decimalPad)
        case .distance:
            TextField("Distance", value: set.distance, format: .number)
                .keyboardType(.decimalPad)
        case .resistance:
            TextField("Resistance", value: set.resistance, format: .number)
                .keyboardType(.decimalPad)
        case .heartRate:
            TextField("Heart Rate", value: set.heartRate, format: .number)
                .keyboardType(.numberPad)
        }
    }

    // MARK: - Actions

    private func addSet() {
        // Prefer the WorkoutEvent date if it exists
        let eventDate = workoutExercise.workoutEvent?.date ?? Date()

        // Normalize so sets always belong to a calendar day (no time component)
        let normalized = Calendar.current.startOfDay(for: eventDate)

        let newSet = WorkoutSet(
            type: workoutExercise.exercise.setType,
            date: normalized
        )

        newSet.workoutExercise = workoutExercise
        newSet.order = workoutExercise.sets.count
        workoutExercise.sets.append(newSet)
    }


    private func deleteSet(at offsets: IndexSet) {
        workoutExercise.sets.remove(atOffsets: offsets)
        for (index, set) in workoutExercise.sets.enumerated() {
            set.order = index
        }
    }

    private func moveSet(from offsets: IndexSet, to newOffset: Int) {
        workoutExercise.sets.move(fromOffsets: offsets, toOffset: newOffset)
        for (index, set) in workoutExercise.sets.enumerated() {
            set.order = index
        }
    }
}

// MARK: - TimerManager & LapHistorySheet

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
    let squat = Exercise(
        name: "Barbell Squat",
        category: .resistance,
        subCategory: .legs
    )
    let deadlift = Exercise(
        name: "Deadlift",
        category: .cardio
    )
    let legPress = Exercise(
        name: "Leg Press",
        category: .resistance,
        subCategory: .legs
    )

    let template = WorkoutTemplate(
        title: "Leg Day"
    )

    let squatExercise = WorkoutExercise(
        notes: "Focus on keeping core tight",
        targetNote: "3 sets of 8 reps @ 75%",
        order: 1,
        workoutTemplate: template,
        exercise: squat
    )

    let deadliftExercise = WorkoutExercise(
        order: 2,
        workoutTemplate: template,
        exercise: deadlift
    )

    let legPressExercise = WorkoutExercise(
        order: 3,
        workoutTemplate: template,
        exercise: legPress
    )

    template.workoutExercises = [squatExercise, deadliftExercise, legPressExercise]

    return WorkoutView(workoutTemplate: template)
        .modelContainer(for: [
            Exercise.self,
            WorkoutTemplate.self,
            WorkoutExercise.self
        ])
}
