//
//  CalendarView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI
import Foundation
import SwiftData

// MARK: - CalendarViewModel
// ObservableObject managing both calendar grid logic and scheduled workout events.
// This version integrates with SwiftData to fetch and observe real WorkoutEvent data.
@MainActor // Add @MainActor here
final class CalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Array of Day objects representing each visible cell in the calendar grid.
    @Published var days: [Day] = []
    
    // The month currently displayed in the calendar.
    @Published var currentDate: Date
    
    // All WorkoutEvents retrieved for the current visible month.
    // This allows the calendar grid and daily workout list to update reactively.
    @Published var events: [WorkoutEvent] = []
    
    
    // MARK: - Private Properties
    
    // The SwiftData context used to fetch and persist WorkoutEvent data.
    // Make this property optional and inject it later.
    private var context: ModelContext?

    // Calendar instance used for date calculations (locale-aware).
    private let calendar = Calendar.current
    
    
    // MARK: - Initializer
    
    /// Initializes the ViewModel with a SwiftData context and populates the current month.
    ///
    /// - Parameter context: The SwiftData `ModelContext` injected from the view hierarchy.
    init() {
        self.currentDate = Date()
        generateDays(for: currentDate)
    }

    /// Sets the model context and fetches the events for the current month.
    func setContext(_ newContext: ModelContext) {
         self.context = newContext
         fetchEventsForCurrentMonth()
     }
    
    
    // MARK: - Fetching Events
    
    func fetchEventsForCurrentMonth() {
        guard let context = context else { return }

        let descriptor = FetchDescriptor<WorkoutEvent>(
            sortBy: [SortDescriptor(\.date)]
        )

        do {
            events = try context.fetch(descriptor)
        } catch {
            print("⚠️ Failed to fetch events: \(error.localizedDescription)")
            events = []
        }
    }
        
    // MARK: - Calendar Grid Generation
    
    /// Generates `Day` objects for the currently visible month,
    /// including padding days from the previous and next months.
    func generateDays(for date: Date) {
        days.removeAll()

        // Ensure we use the user's locale and calendar settings
        var calendar = Calendar.current
        calendar.locale = Locale.current

        // 1️⃣ Get the first day of the target month
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let _ = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return
        }

        // 2️⃣ Determine the weekday offset (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // Compute how many days from the *previous month* to show as padding.
        // If your app’s calendar starts on Monday, use calendar.firstWeekday = 2
        let weekdayOffset = firstWeekday - calendar.firstWeekday
        let leadingPadding = weekdayOffset < 0 ? weekdayOffset + 7 : weekdayOffset

        // 3️⃣ Start date = first visible cell (may be in previous month)
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingPadding, to: firstOfMonth) else {
            return
        }

        // 4️⃣ Total cells = 42 (6 weeks × 7 days)
        // This guarantees a full rectangular calendar grid
        for i in 0..<42 {
            if let dayDate = calendar.date(byAdding: .day, value: i, to: gridStart) {
                let isCurrentMonth = calendar.isDate(dayDate, equalTo: firstOfMonth, toGranularity: .month)
                days.append(Day(date: dayDate, isWithinCurrentMonth: isCurrentMonth))
            }
        }
    }

    
    
    // MARK: - Month Navigation
    
    /// Moves the visible calendar month by the given offset (±1 for next/previous).
    func moveMonth(by offset: Int) {
        if let newDate = calendar.date(byAdding: .month, value: offset, to: currentDate) {
            currentDate = newDate
            generateDays(for: currentDate)
            fetchEventsForCurrentMonth()
        }
    }
    
    
    // MARK: - Display Helpers
    
    /// Returns the header text for the current month (e.g., “October 2025”).
    func monthYearText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentDate)
    }
    
    
    // MARK: - Event Utilities
    
    /// Determines whether a given date has any scheduled WorkoutEvents.
    func hasEvent(on date: Date) -> Bool {
        events.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    /// Returns all WorkoutEvents scheduled for the provided date.
    func events(on date: Date) -> [WorkoutEvent] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func deleteEvent(at offsets: IndexSet) {
        guard let context = context else { return }
        for index in offsets {
            let event = events[index]
            context.delete(event)
        }
        do {
            try context.save()
            fetchEventsForCurrentMonth()
        } catch {
            print("⚠️ Failed to delete event: \(error.localizedDescription)")
        }
    }

    func moveEvent(from source: IndexSet, to destination: Int) {
        var reordered = events
        reordered.move(fromOffsets: source, toOffset: destination)
        events = reordered
    }
    
}



// Day Model
// Represents a single day in the calendar grid
struct Day: Identifiable {
    let id = UUID()
    let date: Date
    let isWithinCurrentMonth: Bool // Helps style previous/next month padding differently
}

// MARK: - Custom Calendar Grid
// This view renders the full monthly calendar grid,
// including the header, weekday labels, and all the day cells.
struct CustomCalendarGrid: View {
    
    // View model that provides the calendar data (days, month/year info)
    @ObservedObject var viewModel: CalendarViewModel
    
    // The date currently selected by the user
    // This comes from the parent view via two-way binding.
    @Binding var selectedDate: Date
    
    // Defines a 7-column grid — one for each day of the week (Sun–Sat)
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // Body
    var body: some View {
        VStack(spacing: 0) {
            
            // Month Header
            // Displays the month and year (e.g., “October 2025”)
            // Includes navigation buttons to move between months.
            HStack {
            
                
                
                Text(viewModel.monthYearText())
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                // “Today” button
                // Resets the view to the current date and highlights today’s cell.
                Button("Today") {
                    withAnimation {
                        let today = Date()
                        selectedDate = today
                        viewModel.currentDate = today
                        viewModel.generateDays(for: today)
                    }
                }
                .font(.subheadline)
                .bold()
                .foregroundColor(.black)
                .buttonStyle(.glass)
//                .padding(.trailing, 20)


                
                Button {
                    viewModel.moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.glass)
//                .buttonBorderShape(.circle)
                
                
             
                Button {
                   viewModel.moveMonth(by: 1)
                } label: {
                   Image(systemName: "chevron.right")
                       .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.glass)
//                .buttonBorderShape(.circle)
                   
            }
            .padding(.horizontal, 18)
//            .padding(.top, 10)
            .padding(.bottom, 10)
            .foregroundStyle(.black)
            
            // MARK: Weekday Labels
            HStack {
                ForEach(["Sun","Mon","Tue","Wed","Thu","Fri","Sat"], id: \.self) { day in
                    Text(day)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 5)

            
            // MARK: Calendar Grid
            // The grid of day cells — one for each Day object provided by the ViewModel.
            // Uses LazyVGrid to efficiently layout and render the calendar.
            LazyVGrid(columns: columns, spacing: 1) {
                
                // Loop through each Day in the ViewModel
                ForEach(viewModel.days) { day in
                    
                    // Check if the current day has any events
                    let hasEvent = viewModel.hasEvent(on: day.date)

                    
                    // Check if this date is today’s date (used to outline “today”)
                    let isToday = Calendar.current.isDateInToday(day.date)
                    
                    // Display the numerical day (e.g., “15”)
                    VStack(spacing: 0) {
                        // --- DAY NUMBER INSIDE THE CIRCLE ---
                        Text("\(Calendar.current.component(.day, from: day.date))")
                            .frame(width: 40, height: 40)
                            .background(
                                ZStack {
                                    if isToday && !Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                        Circle()
                                            .stroke(Color.black, lineWidth: 1)
                                    }
                                    
                                    if hasEvent && !Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                        Circle()
                                            .fill(Color("Button"))
                                    }
                                    
                                    if Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                        Circle()
                                            .fill(Color.black)
                                    }
                                }
                            )
                            .foregroundColor(
                                day.isWithinCurrentMonth
                                ? (Calendar.current.isDate(day.date, inSameDayAs: selectedDate) ? .white : .black)
                                : .gray
                            )

//                        let workouts = viewModel.events(on: day.date)
//                        VStack(spacing: 0) {
//                            if hasEvent {
//                                ForEach(workouts.prefix(1)) { event in
//                                    Text(event.workout.title)
//                                        .font(.system(size: 10))
//                                        .lineLimit(1)
//                                        .truncationMode(.tail)
//                                        .frame(maxWidth: 40)
//                                        .foregroundColor(.black)
//                                }
//
//                            } else {
//                                Text(" ")
//                                    .font(.system(size: 10))
//                                    .frame(maxWidth: 36)
//                                    .opacity(0)
//                            }
//                        }
//                        .frame(height: 10)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            selectedDate = day.date
                            
                            // If tapped day isn't in the current visible month, switch months
                            if !Calendar.current.isDate(day.date, equalTo: viewModel.currentDate, toGranularity: .month) {
                                viewModel.currentDate = day.date
                                viewModel.generateDays(for: day.date)
                                viewModel.fetchEventsForCurrentMonth()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
    }
}

// MARK: - CalendarView
// Displays a monthly calendar with workout events stored in SwiftData.
// The view shows workout indicators on each day and lists scheduled workouts
// for the currently selected date.
struct CalendarView: View {
    
    // MARK: - SwiftData Context
    // Accesses the SwiftData model context (the “database connection” for models).
    // We inject this into the ViewModel so it can fetch and observe WorkoutEvent data.
    @Environment(\.modelContext) private var modelContext

    // MARK: - State Properties
    
    // Tracks which date is currently selected by the user.
    @State private var selectedDate: Date = Date()
    
    // Controls presentation of the “Add Workout” sheet.
    @State private var isAddWorkoutPresented = false
    
    @State private var refreshTask: Task<Void, Never>? = nil
    
    // Creates a single instance of the ViewModel for this view’s lifetime.
    // The ViewModel handles all calendar logic and event fetching.
    @StateObject private var viewModel = CalendarViewModel()



    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            
            VStack(spacing: 0) {
                
                // MARK: - Calendar Grid
                // The calendar grid now highlights days with real WorkoutEvent data.
                CustomCalendarGrid(
                    viewModel: viewModel,
                    selectedDate: $selectedDate
                )
                
                Divider()
                
                // MARK: - Workout List for Selected Date
                List {
                    let events = viewModel.events(on: selectedDate)
                    
                    Section {
                        ForEach(events) { event in
                            HStack {
                                Text(event.workout.title)
                                    .font(.system(.title3, weight: .semibold))
                                Spacer()
                                if let time = event.startTime {
                                    Text(time.formatted(date: .omitted, time: .shortened))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 5)
                            .listRowBackground(Color("Background"))
                        }
                        .onDelete { indexSet in
                            let allEvents = viewModel.events(on: selectedDate)
                            let globalOffsets = IndexSet(indexSet.map { idx in
                                viewModel.events.firstIndex(where: { $0.id == allEvents[idx].id })!
                            })
                            viewModel.deleteEvent(at: globalOffsets)
                        }
                        .onMove { source, destination in
                            viewModel.moveEvent(from: source, to: destination)
                        }
                    }
                    
                    Section {
                        Button {
                            isAddWorkoutPresented = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Workout")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .padding(.vertical, 5)
                            }
                        }
                        .listRowBackground(Color("Background"))
                    }
                }
                .listStyle(.plain)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
            .background(Color("Background"))
            .colorScheme(.light)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                   EditButton()
                       .foregroundColor(.black)
                       .tint(.black)
               
                }

//                ToolbarItem(placement: .principal) {
//                        Text("Calendar")
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .foregroundColor(.black)
//                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddWorkoutPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
//            .navigationBarTitleDisplayMode(.inline)

            .sheet(isPresented: $isAddWorkoutPresented, onDismiss: {
                // Refresh events when the sheet is closed
                viewModel.fetchEventsForCurrentMonth()
            }) {
                WorkoutSelectionView(defaultDate: selectedDate)
                    .presentationDetents([.large])
            }
            // MARK: - Inject Real ModelContext
            // Replace the temporary preview context with the real environment context.
            .onAppear {
                viewModel.setContext(modelContext)
                scheduleMidnightRefresh()
            }
            .onDisappear {
                refreshTask?.cancel()
            }
        }
        
    }
    
    // MARK: - Midnight Refresh Scheduler
    func scheduleMidnightRefresh() {
        refreshTask?.cancel() // Cancel any existing task

        // Compute time interval until next midnight
        let now = Date()
        if let nextMidnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) {
            let interval = nextMidnight.timeIntervalSince(now)
            
            refreshTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                // When midnight arrives, refresh
                await MainActor.run {
                    let today = Date()
                    viewModel.currentDate = today
                    viewModel.generateDays(for: today)
                    viewModel.fetchEventsForCurrentMonth()
                }
                
                // Schedule the next one recursively
                scheduleMidnightRefresh()
            }
        }
    }

    
}

#Preview {
    CalendarView()
}
