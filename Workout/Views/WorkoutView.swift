//
//  WorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//

import SwiftUI
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




@ViewBuilder
private func exerciseList(_ exercises: [WorkoutExercise]) -> some View {
    List {
        ForEach(exercises.sorted(by: { $0.order < $1.order }), id: \.id) { workoutExercise in
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 5) {
                    if let target = workoutExercise.targetNote, !target.isEmpty {
                        Text("Target: \(target)")
                    }
                    if let notes = workoutExercise.notes, !notes.isEmpty {
                        Text("Notes: \(notes)")
                            .foregroundColor(.gray)
                    }
                    Text("Sets will go here")
                        .foregroundColor(.secondary)
                }
            } label: {
                Text(workoutExercise.exercise.name)
                    .font(.system(.title3, weight: .semibold))
            }
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
                                .foregroundColor(.gray)
                            Text(timerManager.formattedTime(timerManager.lapTime))
                                .font(.system(.headline, design: .monospaced))
                        } else {
                            Text("Total")
                                .font(.system(size: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .regular))
                                .foregroundColor(.gray)
                            Text(timerManager.formattedTime(timerManager.elapsedTime))
                                .font(.system(.headline, design: .monospaced))
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
            LapHistorySheet(timerManager: timerManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

struct LapHistorySheet: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        VStack(alignment: .center) {
            Text("Lap History")
                .font(.title2.bold())
                .padding(.top, 10)
            
            if timerManager.lapTimes.isEmpty {
                Text("No laps recorded")
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
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
        .padding()
        .background(Color("Background"))
    }
}



#Preview {
    WorkoutView(workoutTemplate: WorkoutTemplate(title: "Leg Day"))
}
