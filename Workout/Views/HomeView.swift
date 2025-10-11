//
//  HomeView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-11.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workouts: [Workout] = [
        Workout(title: "Leg Day", order: 0, category: .weightlifting),
        Workout(title: "Push Day", order: 1, category: .weightlifting),
        Workout(title: "Run", order: 2, category: .cardio),
        Workout(title: "Tennis", order: 3, category: .other)
    ]

    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            WorkoutListView(
                workouts: workouts,
                addWorkout: { newWorkout in workouts.append(newWorkout) },
                deleteWorkouts: { offsets in workouts.remove(atOffsets: offsets) },
                moveWorkouts: { source, destination in workouts.move(fromOffsets: source, toOffset: destination) },
                isNavBarHidden: .constant(false)
            )
            .tabItem {
                Label("Workouts", systemImage: "list.bullet")
            }
        }
    }
}

