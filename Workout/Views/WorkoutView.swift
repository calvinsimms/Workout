//
//  WorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//
import SwiftUI

struct WorkoutView: View {
    @Bindable var workout: Workout
    @State private var isEditing = false
    
    @State private var timer: Timer?
    @State private var totalTime: TimeInterval = 0
    @State private var lapTime: TimeInterval = 0
    @State private var isRunning = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(workout.title)
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)
            
            Divider()
            
            if workout.exercises.isEmpty {
                Text("No exercises added yet")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                List(workout.exercises, id: \.id) { exercise in
                    Text(exercise.name)
                        .font(.headline)
                        .padding(.vertical, 5)
                }
                .listStyle(.plain)
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                HStack {
                    Text("Total: \(timeFormatted(totalTime))")
                        .font(.title)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Lap: \(timeFormatted(lapTime))")
                        .font(.title2)
                    
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    Button(action: startPauseTimer) {
                        Text(isRunning ? "Stop" : "Start")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isRunning ? Color.gray : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button("Lap") {
                        lapTime = 0
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Reset") {
                        resetTimer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 80)
            }
            
        }
        .foregroundColor(.black)
        .background(Color("Background"))
        .navigationTitle(workout.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                CreateWorkoutView(
                    workout: $workout,
                    isNewWorkout: false
                )
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    func startPauseTimer() {
        if isRunning {
            timer?.invalidate()
        } else {
            let startDate = Date() - totalTime
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                totalTime = Date().timeIntervalSince(startDate)
                lapTime += 0.1
            }
        }
        isRunning.toggle()
    }
    
    func resetTimer() {
        timer?.invalidate()
        totalTime = 0
        lapTime = 0
        isRunning = false
    }
    
    func timeFormatted(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let fraction = Int((interval - floor(interval)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, fraction)
    }
}

#Preview {
    WorkoutView(workout: Workout(title: "Leg Day", exercises: [
        Exercise(name: "Squats"),
        Exercise(name: "Lunges")
    ]))
}


