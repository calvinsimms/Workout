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
    @State private var showTimer = false
    @State private var timer: Timer?
    @State private var totalTime: TimeInterval = 0
    @State private var lapTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var lapHistory: [(number: Int, time: TimeInterval)] = []

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
                .tint(.black)
            }
            
            Spacer()
            
            DisclosureGroup(isExpanded: $showTimer) {
                VStack(spacing: 0) {
                    
//                    Text(timeFormatted(totalTime))
//                        .font(.title.monospacedDigit())
//                        .fontWeight(.bold)
//                        .padding(10)
//                    
//                    Divider()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            if isRunning || lapTime > 0 {
                                HStack {
                                    Text("Lap \(lapHistory.count + 1)")
                                    Spacer()
                                    Text(timeFormatted(lapTime))
                                }
                                .font(.title2.monospacedDigit())
                                .fontWeight(.bold)
                                .padding(.top, 5)
                                
                            }
                            
                            ForEach(lapHistory, id: \.number) { lap in
                                HStack {
                                    Text("Lap \(lap.number)")
                                    Spacer()
                                    Text(timeFormatted(lap.time))
                                        .monospacedDigit()
                                }
                                

                            }
                        }
                    }
                    .font(.title2.monospacedDigit())
                    .frame(height: 130)
                    .padding(.horizontal, 20)
                    
                    
                    Divider()
                        .padding(.bottom, 20)
                    
                    HStack(spacing: 30) {
                        Button((isRunning || totalTime == 0) ? "Lap" : "Reset") {
                            if isRunning || totalTime == 0 {
                                lapHistory.insert((number: lapHistory.count + 1, time: lapTime), at: 0)
                                lapTime = 0
                            } else {
                                resetTimer()
                                lapHistory.removeAll()
                                lapTime = 0
                            }
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color("Button").opacity(0.9))
                        .foregroundColor((!isRunning && totalTime == 0) ? Color("Grayout") : .black)
                        .cornerRadius(30)
                        .shadow(radius: 2)
                        
                        Button(action: startPauseTimer) {
                            Text(isRunning ? "Stop" : "Start")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color("Button").opacity(0.9))
                                .foregroundColor(.black)
                                .cornerRadius(30)
                                .shadow(radius: 2)
                        }
                        
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)

                }
                .padding(.bottom, 20)
                .background(Color("Background"))
                

            } label: {
                HStack {
                    Spacer()
                    Text(showTimer ? timeFormatted(totalTime) : "Timer")
                        .font(.title2.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding()
                
            }
            .background(Color("Button").opacity(0.9))
            .foregroundColor(.black)
            
        }
        .edgesIgnoringSafeArea(.bottom)
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
        .onAppear {
            isNavBarHidden = true
        }
        .onDisappear {
            timer?.invalidate()
            isNavBarHidden = false
        }
    }
    
    func startPauseTimer() {
        if isRunning {
            timer?.invalidate()
        } else {
            let startDate = Date() - totalTime
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                let elapsed = Date().timeIntervalSince(startDate)
                totalTime = elapsed
                lapTime = elapsed - lapHistory.reduce(0) { $0 + $1.time }
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
