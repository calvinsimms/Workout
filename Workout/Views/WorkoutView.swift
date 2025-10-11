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
    
    @Binding var isNavBarHidden: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            Divider()
            
            if workout.exercises.isEmpty {
                Text("No exercises added yet")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                List {
                    ForEach(workout.exercises, id: \.id) { exercise in
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Sets: 3")
                                Text("Reps: 10")
                                Text("Weight: 135 lbs")
                            }
                        } label: {
                            Text(exercise.name)
                                .font(.system(.title2, weight: .bold))
                                .padding(.vertical, 20)
                                .padding(.horizontal, 10)
                        }
                        .listRowBackground(Color("Background"))
                        .listRowInsets(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))

                    }
                }
                .listStyle(.plain)
                .padding(.trailing, 20)
                

            }
            
            Spacer()
            
            VStack(spacing: 10) {
                HStack {
                    Text("Total: \(timeFormatted(totalTime))")
                        .font(.title)
                    
                    Spacer()
                    Text("Lap: \(timeFormatted(lapTime))")
                        .font(.title2)
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 20) {
                    Button(action: startPauseTimer) {
                        Text(isRunning ? "Stop" : "Start")
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(isRunning ? Color.gray : Color.gray)
                            .foregroundColor(.black)
                            .cornerRadius(30)
                    }
                    
                    Button("Lap") {
                        lapTime = 0
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.gray)
                    .foregroundColor(.black)
                    .cornerRadius(30)
                    
                    Button("Reset") {
                        resetTimer()
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.gray)
                    .foregroundColor(.black)
                    .cornerRadius(30)
                }
                .padding(.horizontal, 20)
                
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
        .navigationDestination(isPresented: $isEditing) {
            CreateWorkoutView(
                workout: $workout,
                isNewWorkout: false
            )
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onAppear {
           isNavBarHidden = true
        }
        .onDisappear {
            isNavBarHidden = false
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
    WorkoutView(
        workout: Workout(title: "Leg Day", exercises: [
            Exercise(name: "Squats"),
            Exercise(name: "Lunges")
        ]),
        isNavBarHidden: .constant(false) 
    )
}

