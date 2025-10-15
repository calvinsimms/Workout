//
//  CalendarView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI
import UIKit // Needed for some UIKit integrations (like haptics if added later)

// MARK: - Event Model for Placeholders
// Simple struct representing an event (workout) on a specific date for temporary
// workout placeholders until actual workouts are integrated
struct Event: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
}

let sampleEvents: [Event] = [
    Event(date: Date(), title: "Pull Day"),
    Event(date: Date(), title: "Running"),
    Event(date: Date(), title: "Chest")
]

// MARK: - Calendar ViewModel
// ObservableObject managing the state and logic for the calendar grid
// This ViewModel is responsible for generating the days to display,
// tracking the currently visible month, and handling month navigation.
class CalendarViewModel: ObservableObject {
    
    // Published Properties
    
    @Published var days: [Day] = []
    /*
     Array of Day objects representing each cell in the calendar grid.
     SwiftUI observes this array, so the UI automatically updates when days change.
     Each Day contains:
       - date: actual Date object
       - isWithinCurrentMonth: whether the day belongs to the visible month or is padding from previous/next month
    */
    
    @Published var currentDate: Date
    /*
     The currently displayed month in the calendar.
     Initialized to today's date, but changes when the user navigates months.
     Used to generate the days for the grid.
    */
    
    // Private Properties
    private let calendar = Calendar.current
    /*
     Calendar instance used for all date calculations:
       - Finding the number of days in a month
       - Determining the first weekday
       - Adding/subtracting months or days
     Using Calendar.current respects the user's locale and calendar settings.
    */
    
    // Initializer
    init() {
        self.currentDate = Date() // Start at today
        generateDays(for: currentDate) // Populate the calendar for the current month
    }
    
    // Generate Days for Month
    func generateDays(for date: Date) {
        /*
         Generates Day objects to fill a full calendar grid:
         - Includes previous and next month padding to complete weeks.
         - Ensures the grid always has full rows (7 columns for weekdays).
         - Updates the `days` array which drives the SwiftUI grid.
        */
        
        days.removeAll() // Clear existing days before generating new ones
        
        // 1. Determine number of days in current month
        let range = calendar.range(of: .day, in: .month, for: date)!
        
        // 2. Determine the first day of the current month
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        
        // 3. Determine weekday index for the first day (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        // 4. Add previous month's days as padding (to align first day correctly)
        let prevMonth = calendar.date(byAdding: .month, value: -1, to: date)!
        let prevMonthRange = calendar.range(of: .day, in: .month, for: prevMonth)!
        for day in (prevMonthRange.count - (firstWeekday - 2))...prevMonthRange.count {
            if let date = calendar.date(bySetting: .day, value: day, of: prevMonth) {
                days.append(Day(date: date, isWithinCurrentMonth: false))
            }
        }
        
        // 5. Add all days for the current month
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: date) {
                days.append(Day(date: date, isWithinCurrentMonth: true))
            }
        }
        
        // 6. Add next month's days as padding (to fill the last row)
        while days.count % 7 != 0 {
            if let nextMonthDate = calendar.date(byAdding: .day, value: 1, to: days.last!.date) {
                days.append(Day(date: nextMonthDate, isWithinCurrentMonth: false))
            }
        }
    }
    
    // Navigate Months
    func moveMonth(by offset: Int) {
        /*
         Changes the visible month by the specified offset:
         - Positive offset moves forward
         - Negative offset moves backward
         After updating currentDate, regenerate the days for the new month.
        */
        if let newDate = calendar.date(byAdding: .month, value: offset, to: currentDate) {
            currentDate = newDate
            generateDays(for: currentDate)
        }
    }
    
    // Month + Year Display
    func monthYearText() -> String {
        /*
         Returns a string for the header of the calendar, e.g., "October 2025".
         - Uses DateFormatter with format "LLLL yyyy":
           - "LLLL" = full month name
           - "yyyy" = full year
        */
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentDate)
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
        VStack(spacing: 5) {
            
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
                .padding(6)
                .background(Color("Button").opacity(0.9))
                .cornerRadius(10)
                .foregroundColor(.black)
                .padding(.trailing, 20)
                .shadow(radius: 2)
                
                // Navigate to the previous month
                Button("<") {
                    viewModel.moveMonth(by: -1)
                }
                .font(.title)
                .padding(.trailing, 20)
                
                // Navigate to the next month
                Button(">") {
                    viewModel.moveMonth(by: 1)
                }
                .font(.title)
            }
            .padding(.horizontal, 20)
            .padding(.vertical)
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
            .padding(.bottom, 10)
            
            // MARK: Calendar Grid
            // The grid of day cells — one for each Day object provided by the ViewModel.
            // Uses LazyVGrid to efficiently layout and render the calendar.
            LazyVGrid(columns: columns, spacing: 10) {
                
                // Loop through each Day in the ViewModel
                ForEach(viewModel.days) { day in
                    
                    // Check if the current day has any events
                    // (Uses temporary sample data for now — will later connect to real workouts)
                    let hasEvent = sampleEvents.contains { event in
                        Calendar.current.isDate(event.date, inSameDayAs: day.date)
                    }
                    
                    // Check if this date is today’s date (used to outline “today”)
                    let isToday = Calendar.current.isDateInToday(day.date)
                    
                    // Display the numerical day (e.g., “15”)
                    Text("\(Calendar.current.component(.day, from: day.date))")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            ZStack {
                                
                                // 1. Outline today’s date if it’s not currently selected
                                if isToday && !Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                }
                                
                                // 2. Fill the day with a color if there’s an event (but it’s not selected)
                                if hasEvent && !Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                    Circle()
                                        .fill(Color("Button"))
                                }
                                
                                // 3. Fill the day solid black if it’s the currently selected date
                                if Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                    Circle()
                                        .fill(Color.black)
                                        .transition(.opacity)
                                }
                            }
                        )
                        .animation(.easeInOut(duration: 0.3), value: selectedDate)
                        
                        // Text color logic:
                        // - White for selected date
                        // - Black for normal current-month days
                        // - Gray for days that belong to adjacent months
                        .foregroundColor(
                            day.isWithinCurrentMonth
                            ? (Calendar.current.isDate(day.date, inSameDayAs: selectedDate) ? .white : .black)
                            : .gray
                        )
                        
                        // Makes the entire cell tappable
                        .contentShape(Rectangle())
                        
                        // When tapped, set selectedDate to this day (with animation)
                        .onTapGesture {
                            withAnimation {
                                selectedDate = day.date
                            }
                        }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Main Calendar
// Displays a monthly calendar, highlights days with workouts (events),
// and lists workouts for the currently selected day.
struct CalendarView: View {
    
    // MARK: State Properties
    // Tracks which day is currently selected by the user.
    // Defaults to today’s date when the view first loads.
    @State private var selectedDate: Date = Date()
    
    // Controls whether the “Add Exercise” sheet (modal) is visible.
    // Set to true when the user taps the plus button in the header.
    @State private var isAddExercisePresented = false
    
    // View model responsible for generating calendar data.
    // @StateObject ensures it is created once and stays alive
    // as long as this view exists.
    @StateObject private var calendarVM = CalendarViewModel()
    
    
    // MARK: Computed Property: Events for Selected Day
    // Filters the sampleEvents array to include only those
    // whose date matches the currently selectedDate.
    private var eventsForSelectedDate: [Event] {
        sampleEvents.filter { event in
            Calendar.current.isDate(event.date, inSameDayAs: selectedDate)
        }
    }
    
    
    // MARK: Body
    var body: some View {
        VStack(spacing: 0) { // Stack header, grid, and event list vertically
            
            // MARK: Header
            HStack {
                // Left: Pencil icon (future use for editing, e.g., rename or edit workouts)
                Image(systemName: "pencil")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color("Button").opacity(0.9))
                    .cornerRadius(30)
                    .shadow(radius: 2)
                    .padding(.bottom, 10)
                
                Spacer()
                
                // Center: "Calendar" title text
                Text("Calendar")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                
                Spacer()
                
                // Right: Add new workout button (plus icon)
                // Opens a sheet to add a new workout or exercise entry
                Button(action: {
                    isAddExercisePresented = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color("Button").opacity(0.9))
                        .cornerRadius(30)
                        .shadow(radius: 2)
                        .padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 20)
            
            Divider()
            
            
            // MARK: Custom Calendar Grid
            // Displays a full month calendar grid with selectable days

            CustomCalendarGrid(
                viewModel: calendarVM,
                selectedDate: $selectedDate // Two-way binding for selection
            )
            
            
            Divider()
            
            
            // MARK: Event List for Selected Day
            // Displays all workouts/events for the currently selected date.
            List {
                ForEach(eventsForSelectedDate) { event in
                    HStack {
                        Text(event.title)
                    }
                    .font(.system(.title2, weight: .bold))
                    .padding(.vertical, 10)
                    // Custom background color for list rows
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
        
        // MARK: - Add Exercise Sheet
        // When triggered by the plus button, a modal sheet appears.
        // Currently a placeholder — will be replaced with CreateWorkoutView later.
        .sheet(isPresented: $isAddExercisePresented) {
            Text("Add Workouts View")
        }
    }
}
#Preview {
    CalendarView()
}
