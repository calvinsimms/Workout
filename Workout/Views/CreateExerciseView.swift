//
//  CreateExerciseView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-06.
//

import SwiftUI
import SwiftData

// MARK: - CreateExerciseView
// A reusable form view for creating or editing an Exercise object.
//
// Supports two modes:
//   - **New Exercise**: Creates a brand-new exercise and inserts it into SwiftData
//   - **Edit Exercise**: Allows editing an existing exercise passed in from elsewhere
//
// The view uses bindings and environment contexts to seamlessly integrate
// with SwiftData and SwiftUI navigation flows.
struct CreateExerciseView: View {
    
    // MARK: - Bound & Environment Properties
    
    // Binding to an Exercise object.
    // Used for both creating new exercises and editing existing ones.
    @Binding var exercise: Exercise
    
    // Determines whether this view is for creating a new exercise
    // or editing an existing one. Controls title and save behavior.
    var isNewExercise: Bool
    
    // Optional closure that runs after the save button is tapped.
    // Useful for triggering refresh actions in parent views.
    var onSave: (() -> Void)?
    
    // Provides the ability to dismiss this sheet or navigation view programmatically.
    @Environment(\.dismiss) var dismiss
    
    // Gives access to SwiftData’s model context for saving or inserting objects.
    @Environment(\.modelContext) private var modelContext
    
    // Fetches all existing exercises to check for duplicates before saving.
    @Query(sort: \Exercise.name, order: .forward) private var existingExercises: [Exercise]
    
    // Controls whether the duplicate name alert is shown.
    @State private var showingDuplicateAlert = false

    
    var defaultCategory: WorkoutCategory? = nil
    
    // Stores the currently selected category for this exercise.
    // Defaults based on any existing subcategory or `.other` for new exercises.
    @State private var selectedCategory: WorkoutCategory
    
    // Stores the selected subcategory when the exercise is of type Resistance.
    @State private var selectedSubCategory: SubCategory?
    
    
    // MARK: - Initializer
    init(
        exercise: Binding<Exercise>,
        isNewExercise: Bool,
        defaultCategory: WorkoutCategory? = nil,
        onSave: (() -> Void)? = nil
    ) {
        self._exercise = exercise
        self.isNewExercise = isNewExercise
        self.defaultCategory = defaultCategory
        self.onSave = onSave
        
        // Initialize category & subcategory intelligently
        if let sub = exercise.wrappedValue.subCategory {
            // If exercise already has a subcategory, derive category from it
            _selectedCategory = State(initialValue: sub.parentCategory)
            _selectedSubCategory = State(initialValue: sub)
        } else if let defaultCategory {
            // If parent workout provided a default category (e.g. from CreateWorkoutView)
            _selectedCategory = State(initialValue: defaultCategory)
            _selectedSubCategory = State(initialValue: nil)
        } else {
            // Otherwise fallback to resistance
            _selectedCategory = State(initialValue: .resistance)
            _selectedSubCategory = State(initialValue: nil)
        }
    }
    
    
    // MARK: - Body
    var body: some View {
        
        Form {
            
            // Exercise Name Input
            Section(header: Text("Exercise Name")) {
                TextField("Name", text: $exercise.name)
            }
            
            // Category Selection
            Section(header: Text("Category")) {
                // Picker with same segmented style used in CreateWorkoutView
                Picker("Category", selection: $selectedCategory) {
                    ForEach(WorkoutCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Subcategory Picker (only visible if Resistance is selected)
            if selectedCategory == .resistance {
                Section(header: Text("Subcategory")) {
                    Picker("Subcategory", selection: Binding(
                        get: { selectedSubCategory ?? .chest }, // default to Chest if nil
                        set: { newValue in
                            selectedSubCategory = newValue
                            exercise.subCategory = newValue
                        }
                    )) {
                        ForEach(SubCategory.allCases) { sub in
                            Text(sub.rawValue).tag(sub)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    Toggle("Bodyweight Exercise", isOn: $exercise.isBodyweight)
                        .tint(.blue)
                        .accessibilityLabel("Marks this exercise as bodyweight only")
                } footer: {
                    Text("Enable this if the exercise uses only your body weight (e.g. Push-Ups, Pull-Ups).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        // MARK: - Navigation Title
        .navigationTitle(isNewExercise ? "New Exercise" : "Edit Exercise")
        
        // MARK: - Toolbar Buttons
        .toolbar {
            
            // Confirmation (Save) Button
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let trimmedName = exercise.name.trimmingCharacters(in: .whitespaces)
                    
                    // Duplicate check (same as before)
                    let isDuplicate = existingExercises.contains {
                        $0.name.lowercased() == trimmedName.lowercased() && $0.id != exercise.id
                    }
                    guard !isDuplicate else {
                        showingDuplicateAlert = true
                        return
                    }
                    
                    // Reapply defaults before saving
                    exercise.category = selectedCategory
                    if selectedCategory == .resistance {
                        exercise.subCategory = selectedSubCategory ?? .chest
                    } else {
                        exercise.subCategory = nil
                    }
                    
                    if isNewExercise {
                        modelContext.insert(exercise)
                    }
                    
                    onSave?()
                    dismiss()
                }

                .alert("Duplicate Exercise", isPresented: $showingDuplicateAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("An exercise with this name already exists. Please choose a different name.")
                }
                .disabled(exercise.name.trimmingCharacters(in: .whitespaces).isEmpty)

            }
            
        }
        .onAppear {
            // Ensure both are initialized before saving
            exercise.category = selectedCategory
            
            if selectedCategory == .resistance {
                // If no subcategory was chosen, default to Chest
                if selectedSubCategory == nil {
                    selectedSubCategory = .chest
                }
                exercise.subCategory = selectedSubCategory
            } else {
                exercise.subCategory = nil
            }
        }


    }
    
}


// MARK: - Preview
#Preview {
    @Previewable @State var sampleExercise = Exercise(name: "Bench Press", subCategory: .chest)
    
    NavigationStack {
        CreateExerciseView(
            exercise: $sampleExercise,
            isNewExercise: true,
            onSave: {
                print("Saved exercise: \(sampleExercise.name)")
            }
        )
    }
}
