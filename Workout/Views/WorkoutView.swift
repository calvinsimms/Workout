//
//  WorkoutView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-07.
//

import SwiftUI

/// View displaying a single workout, its exercises, and a built-in timer with laps.
struct WorkoutView: View {
    // MARK: - Bindings & State
    
    /// The workout being displayed and editable via child views.
    @Bindable var workout: Workout
    
    /// Tracks whether the workout is in editing mode.
    @State private var isEditing = false
    
    /// Controls the visibility of the timer section.
    @State private var showTimer = false
    
    /// Timer object used for counting time.
    @State private var timer: Timer?
    
    /// Total elapsed time since timer started.
    @State private var totalTime: TimeInterval = 0
    
    /// Elapsed time for the current lap.
    @State private var lapTime: TimeInterval = 0
    
    /// Indicates whether the timer is currently running.
    @State private var isRunning = false
    
    /// History of recorded laps with lap number and duration.
    @State private var lapHistory: [(number: Int, time: TimeInterval)] = []
    
    /// Optional workout notes (currently not displayed).
    @State private var notes: String = ""
    
    /// Binding to control visibility of the parent navigation bar.
    @Binding var isNavBarHidden: Bool
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            
            Divider()
            
            // MARK: - Exercise List
            if workout.exercises.isEmpty {
                // Display placeholder text if no exercises exist.
                Text("No exercises added yet")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                // Display exercises in a scrollable list with disclosure groups.
                List {
                    ForEach(workout.exercises, id: \.id) { exercise in
                        DisclosureGroup {
                            // Hardcoded exercise details for now.
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Sets: 3")
                                Text("Reps: 10")
                                Text("Weight: 135 lbs")
                            }
                        } label: {
                            // Exercise name displayed prominently.
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
            
            // MARK: - Timer Section
            DisclosureGroup(isExpanded: $showTimer) {
                VStack(spacing: 0) {
                    
                    // Scrollable area showing lap times.
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            
                            // Current lap display
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
                            
                            // Display past lap history
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
                        .padding(.bottom, 30)
                    
                    // MARK: - Timer Controls
                    HStack(spacing: 30) {
                        
                        // Lap or Reset button
                        Button((isRunning || totalTime == 0) ? "Lap" : "Reset") {
                            if isRunning || totalTime == 0 {
                                // Record current lap
                                lapHistory.insert((number: lapHistory.count + 1, time: lapTime), at: 0)
                                lapTime = 0
                            } else {
                                // Reset timer completely
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
                        
                        // Start / Stop button
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
                // Timer header display
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
        // MARK: - View Styling
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
        // Navigate to workout editing view
        .navigationDestination(isPresented: $isEditing) {
            CreateWorkoutView(
                workout: $workout,
                isNewWorkout: false
            )
        }
        // Hide navigation bar when view appears
        .onAppear {
            isNavBarHidden = true
        }
        // Clean up timer when leaving view and restore nav bar
        .onDisappear {
            timer?.invalidate()
            isNavBarHidden = false
        }
    }
    
    // MARK: - Timer Functions

    /// Starts or pauses the workout timer.
    func startPauseTimer() {
        if isRunning {
            // Timer is currently running, so we stop it.
            // Invalidate cancels the scheduled Timer, preventing further updates.
            timer?.invalidate()
        } else {
            // Timer is not running, so start it.
            // Calculate the starting point based on totalTime to resume from where it left off.
            let startDate = Date() - totalTime
            
            // Schedule a repeating timer to update every 0.01 seconds.
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                // Calculate elapsed time from the adjusted startDate.
                let elapsed = Date().timeIntervalSince(startDate)
                
                // Update totalTime to reflect the overall workout duration.
                totalTime = elapsed
                
                // Lap time is calculated as totalTime minus the sum of all previous lap times.
                // This ensures each lap counts only the time since the last lap.
                lapTime = elapsed - lapHistory.reduce(0) { $0 + $1.time }
            }
        }
        
        // Toggle the running state of the timer.
        // This affects button labels and whether the timer logic continues updating.
        isRunning.toggle()
    }

    
    /// Resets the timer and clears lap history.
    func resetTimer() {
        // Stop the timer to prevent further updates.
        timer?.invalidate()
        
        // Reset all time-related variables to zero.
        totalTime = 0
        lapTime = 0
        
        // Set the running state to false.
        isRunning = false
    }
    
    /// Formats a TimeInterval into a string `MM:SS.d`
    /// - Parameter interval: TimeInterval to format
    /// - Returns: Formatted string like `02:35.7`
    func timeFormatted(_ interval: TimeInterval) -> String {
        // Calculate minutes by dividing total seconds by 60
        let minutes = Int(interval) / 60
        
        // Seconds is the remainder after removing minutes
        let seconds = Int(interval) % 60
        
        // Fractional part of a second (tenths)
        let fraction = Int((interval - floor(interval)) * 10)
        
        // Format as "MM:SS.d", with leading zeros for minutes and seconds
        return String(format: "%02d:%02d.%d", minutes, seconds, fraction)
    }

}

// MARK: - Preview
#Preview {
    WorkoutView(
        workout: Workout(title: "Leg Day", exercises: [
            Exercise(name: "Squats"),
            Exercise(name: "Lunges")
        ]),
        isNavBarHidden: .constant(false)
    )
}
