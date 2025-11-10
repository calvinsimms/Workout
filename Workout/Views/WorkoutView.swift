//
//  WorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//

import SwiftUI
import SwiftData
import Combine

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
        timer = Timer.publish(every: 1/60, on: .main, in: .common)
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

struct SetsInputSection: View {
    @State private var sets: [UUID] = []
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var rpe: String = ""
    @State private var duration: String = ""
    @State private var distance: String = ""
    @State private var resistance: String = ""
    @State private var heartRate: String = ""
    @State private var isEditing = false

    let workoutExercise: WorkoutExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            HStack {
                Text("Sets")
                    .font(.headline)
                Spacer()
                EditButton()
                    .buttonStyle(.glass)
                    .opacity(sets.isEmpty ? 0 : 1)
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
                ForEach(Array(sets.enumerated()), id: \.element) { index, _ in
                    HStack {
                        Text("\(index + 1)")
                            .frame(width: 20, alignment: .leading)

                        switch workoutExercise.exercise.setType {
                        case .resistance:
                            TextField("Weight", text: $weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)

                            TextField("Reps", text: $reps)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)

                            TextField("RPE", text: $rpe)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)

                        case .bodyweight:
                            TextField("Reps", text: $reps)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)

                            TextField("RPE", text: $rpe)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)

                        case .cardio:
                            TextField("Duration", text: $duration)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)

                            TextField("Distance", text: $distance)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)

                            TextField("Heart Rate", text: $heartRate)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                        }
                    }
                    .listRowBackground(Color("Background"))

                }
                .onDelete(perform: deleteSet)
                .onMove(perform: moveSet)
            }
            .frame(height: CGFloat(sets.count) * 44 + 20)
            .listStyle(.plain)
        }
    }

    // MARK: - Actions
    private func addSet() {
        withAnimation {
            sets.append(UUID())
        }
    }

    private func deleteSet(at offsets: IndexSet) {
        withAnimation {
            sets.remove(atOffsets: offsets)
        }
    }

    private func moveSet(from source: IndexSet, to destination: Int) {
        withAnimation {
            sets.move(fromOffsets: source, toOffset: destination)
        }
    }
}




@ViewBuilder
private func exerciseList(_ exercises: [WorkoutExercise]) -> some View {
    List {
        ForEach(exercises.sorted(by: { $0.order < $1.order }), id: \.id) { workoutExercise in
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 0) {
                    
                    Text("Targets")
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    TextField("Targets", text: Binding(
                        get: { workoutExercise.targetNote ?? "" },
                        set: { workoutExercise.targetNote = $0 }
                    ))
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    
                    
                    Divider()
                        .padding(.vertical, 10)

                    SetsInputSection(workoutExercise: workoutExercise)
                    
                    Text("Notes")
                        .font(.headline)
                        .padding(.bottom, 10)

                    
                    TextField("Notes", text: Binding(
                        get: { workoutExercise.notes ?? "" },
                        set: { workoutExercise.notes = $0 }
                    ))
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                                    }
            } label: {
                Text(workoutExercise.exercise.name)
                    .font(.system(.title3, weight: .semibold))
            }
            .padding(.vertical, 5)
            .listRowBackground(Color("Background"))

        }
    }
    .listStyle(.plain)
    .tint(.black)
}



struct WorkoutView: View {
    var workoutEvent: WorkoutEvent?
    var workoutTemplate: WorkoutTemplate?

    @State private var isEditing = false
    @State private var notes: String = ""
    @StateObject private var timerManager = TimerManager()
    @State private var showingLapTime = false
    @State private var showingLapHistory = false


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
                    exerciseList(event.workoutExercises)
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
                    exerciseList(template.workoutExercises)
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
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .regular))
                            Text(timerManager.formattedTime(timerManager.lapTime))
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .regular, design: .monospaced))
                        } else {
                            Text("Total")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .regular))
                            Text(timerManager.formattedTime(timerManager.elapsedTime))
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .regular, design: .monospaced))
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }

                // LAP / RESET BUTTON
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

                // START / STOP BUTTON
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
                WorkoutSelectionView(defaultDate: event.date)
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
    // MARK: - Mock Exercises
    let squat = Exercise(
        name: "Barbell Squat",
        category: .resistance,
        subCategory: .legs
    )
    let deadlift = Exercise(
        name: "Deadlift",
        category: .cardio,
        
    )
    let legPress = Exercise(
        name: "Leg Press",
        category: .resistance,
        subCategory: .legs
    )

    // MARK: - Mock Workout Template
    let template = WorkoutTemplate(
        title: "Leg Day"
    )

    // MARK: - Mock Workout Exercises
    let squatExercise = WorkoutExercise(
        notes: "Focus on keeping core tight",
        targetNote: "3 sets of 8 reps @ 75%",
        order: 1,
        workoutTemplate: template,
        exercise: squat
    )

    let deadliftExercise = WorkoutExercise(
//        notes: "Flat back, engage lats before lift",
//        targetNote: "3 sets of 5 reps @ 80%",
        order: 2,
        workoutTemplate: template,
        exercise: deadlift
    )

    let legPressExercise = WorkoutExercise(
//        notes: "Slow negatives, full depth",
//        targetNote: "4 sets of 12 reps",
        order: 3,
        workoutTemplate: template,
        exercise: legPress
    )

    // Attach the exercises to the template
    template.workoutExercises = [squatExercise, deadliftExercise, legPressExercise]

    // MARK: - Return the Preview
    return WorkoutView(workoutTemplate: template)
        .modelContainer(for: [
            Exercise.self,
            WorkoutTemplate.self,
            WorkoutExercise.self
        ])
}

