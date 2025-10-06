//
//  ExerciseSelectionView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI


struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

struct ExerciseSelectionView: View {
    @Binding var selectedExercises: Set<Exercise>
    @State private var exercises: [Exercise] = []

    var body: some View {
        List(exercises, id: \.self) { exercise in
            Button {
                if selectedExercises.contains(exercise) {
                    selectedExercises.remove(exercise)
                } else {
                    selectedExercises.insert(exercise)
                }
            } label: {
                HStack {
                    Text(exercise.name)
                    Spacer()
                    if selectedExercises.contains(exercise) {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        .navigationTitle("Select Exercises")
        .onAppear {
            
        }
    }
}

#Preview {
    // Create a sample set of exercises
    let sampleExercises: Set<Exercise> = [
        Exercise(name: "Push Ups"),
        Exercise(name: "Squats")
    ]
    
    // Use @State to wrap it for binding
    StatefulPreviewWrapper(sampleExercises) { binding in
        ExerciseSelectionView(selectedExercises: binding)
    }
}
