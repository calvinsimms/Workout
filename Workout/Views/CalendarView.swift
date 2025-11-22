//
//  CalendarView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//  Modernized 2025-11-15
//

import SwiftUI
import Foundation
import SwiftData

// MARK: - Day Model

struct Day: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let isWithinCurrentMonth: Bool
}

// MARK: - DayCell (Equatable to minimize re-renders)

private struct DayCellView: View, Equatable {
    static func == (lhs: DayCellView, rhs: DayCellView) -> Bool {
        lhs.day == rhs.day &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isToday == rhs.isToday &&
        lhs.hasEvent == rhs.hasEvent
    }

    let day: Day
    let isSelected: Bool
    let isToday: Bool
    let hasEvent: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("\(Calendar.current.component(.day, from: day.date))")
                .frame(width: 40, height: 40)
                .background(
                    ZStack {
                        if isToday && !isSelected {
                            Circle().stroke(Color.black, lineWidth: 1)
                        }
                        if hasEvent && !isSelected {
                            Circle().fill(Color("Button"))
                        }
                        if isSelected {
                            Circle().fill(Color.black)
                        }
                    }
                )
                .foregroundColor(
                    day.isWithinCurrentMonth
                    ? (isSelected ? .white : .black)
                    : .gray
                )
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .contentShape(Rectangle())
    }
}

// MARK: - Custom Calendar Grid

struct CustomCalendarGrid: View {

    @Binding var selectedDate: Date
    @Binding var currentMonthDate: Date
    let hasEvent: (Date) -> Bool

    @State private var days: [Day] = []

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = .current
        return cal
    }

    var body: some View {
        VStack(spacing: 0) {

            // Weekday Labels
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 5)

            // Grid
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(days) { day in
                    let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
                    let isToday = calendar.isDateInToday(day.date)
                    let hasEventForDay = hasEvent(day.date)

                    DayCellView(
                        day: day,
                        isSelected: isSelected,
                        isToday: isToday,
                        hasEvent: hasEventForDay
                    )
                    .onTapGesture {
                        withAnimation(.snappy) {
                            selectedDate = day.date

                            // If tapping a padding day, jump months
                            if !calendar.isDate(day.date, equalTo: currentMonthDate, toGranularity: .month) {
                                if let newMonth = calendar.date(
                                    from: calendar.dateComponents([.year, .month], from: day.date)
                                ) {
                                    currentMonthDate = newMonth
                                    generateDays(for: newMonth)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 6)

            HStack {

                Button("Today") {
                    let today = Date()
                    selectedDate = today
                    if let thisMonth = calendar.date(
                        from: calendar.dateComponents([.year, .month], from: today)
                    ) {
                        currentMonthDate = thisMonth
                        generateDays(for: thisMonth)
                    }
                }
                .font(.subheadline).bold()
                .buttonStyle(.glass)
                
                Spacer()
                
                GlassEffectContainer(spacing: 30.0) {
                    HStack {
                        Button {
                            moveMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.glass)
                        
                        Button {
                            moveMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.glass)
                    }
                }

            }
            .foregroundStyle(.black)
        }
        .background(Color("Background"))

        .onAppear {
            generateDays(for: currentMonthDate)
        }
        .onChange(of: currentMonthDate) {
            generateDays(for: currentMonthDate)
        }
    }

    // MARK: - Helpers

    private func moveMonth(by offset: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: offset, to: currentMonthDate) else { return }
        currentMonthDate = newDate
        generateDays(for: newDate)
    }

    private func generateDays(for date: Date) {
        days.removeAll(keepingCapacity: true)

        guard let firstOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ),
        let _ = calendar.range(of: .day, in: .month, for: firstOfMonth)
        else { return }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let weekdayOffset = firstWeekday - calendar.firstWeekday
        let leadingPadding = weekdayOffset < 0 ? weekdayOffset + 7 : weekdayOffset

        guard let gridStart = calendar.date(byAdding: .day, value: -leadingPadding, to: firstOfMonth) else { return }

        days.reserveCapacity(42)
        for i in 0..<42 {
            if let dayDate = calendar.date(byAdding: .day, value: i, to: gridStart) {
                let isCurrentMonth = calendar.isDate(dayDate, equalTo: firstOfMonth, toGranularity: .month)
                days.append(Day(date: dayDate, isWithinCurrentMonth: isCurrentMonth))
            }
        }
    }
}

// MARK: - CalendarView

struct CalendarView: View {

    @Environment(\.modelContext) private var modelContext

    // All workout events, live-updating via SwiftData
    @Query(sort: [
        SortDescriptor(\WorkoutEvent.date, order: .forward),
        SortDescriptor(\WorkoutEvent.order, order: .forward)
    ])
    private var allEvents: [WorkoutEvent]
    
    @Query(sort: [SortDescriptor(\MeasurementEvent.date, order: .forward)])
    private var allMeasurementEvents: [MeasurementEvent]

    @State private var selectedDate: Date = Date()
    @State private var currentMonthDate: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    ) ?? Date()

    @State private var isAddWorkoutPresented = false

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = .current
        return cal
    }
    
    private enum DayEvent: Identifiable {
        case workout(WorkoutEvent)
        case measurement(MeasurementEvent)

        var id: UUID {
            switch self {
            case .workout(let w): return w.id
            case .measurement(let m): return m.id
            }
        }

        var order: Int {
            switch self {
            case .workout(let w): return w.order
            case .measurement(let m): return m.order
            }
        }

        var displayTitle: String {
            switch self {
            case .workout(let w): return w.displayTitle
            case .measurement: return "Measurements"
            }
        }
    }
    
    

    // Events for the currently selected day
//    private var eventsForSelectedDate: [WorkoutEvent] {
//        allEvents
//            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
//            .sorted { lhs, rhs in
//                if lhs.order != rhs.order {
//                    return lhs.order < rhs.order
//                }
//                let lTime = lhs.startTime ?? lhs.date
//                let rTime = rhs.startTime ?? rhs.date
//                return lTime < rTime
//            }
//    }
    
    private var eventsForSelectedDate: [DayEvent] {
        let workouts = allEvents
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .map { DayEvent.workout($0) }

        let measurements = allMeasurementEvents
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .map { DayEvent.measurement($0) }

        return (workouts + measurements)
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            List {
                CustomCalendarGrid(
                    selectedDate: $selectedDate,
                    currentMonthDate: $currentMonthDate,
                    hasEvent: { date in hasEvent(on: date) }
                )            .listRowBackground(Color("Background"))



                let dayEvents = eventsForSelectedDate
                let workoutEvents = dayEvents.compactMap { event -> WorkoutEvent? in
                    if case .workout(let w) = event { return w }
                    else { return nil }
                }

                if workoutEvents.isEmpty {
                    Text("No workouts planned today")
                        .foregroundColor(.gray)
                        .italic()
                        .padding(.vertical, 5)
                        .listRowBackground(Color("Background"))
                } else {
                    ForEach(workoutEvents) { event in
                        NavigationLink {
                            if let template = event.workoutTemplate {
                                WorkoutView(workoutTemplate: template)
                            } else {
                                WorkoutView(workoutEvent: event)
                            }
                        } label: {
                            Text(event.displayTitle)
                                .font(.title3.bold())
                                .padding(.vertical, 5)
                        }
                        .listRowBackground(Color("Background"))
                    }
                    .onDelete { offsets in
                        deleteEvents(at: offsets, in: workoutEvents)
                    }
                    .onMove { source, destination in
                        moveEvents(from: source, to: destination, in: workoutEvents)
                    }
                }

                    
                
          
            }
            .listStyle(GroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle(Text(Self.monthYearFormatter.string(from: currentMonthDate)))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .foregroundColor(.black)
                        .tint(.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddWorkoutPresented = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $isAddWorkoutPresented) {
                NavigationStack {
                    VStack(spacing: 0) {
                        WorkoutSelectionView(date: $selectedDate)
                    }
                    .navigationTitle("Add Event")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    // MARK: - Helpers
//
//    private func hasEvent(on date: Date) -> Bool {
//        allEvents.contains { calendar.isDate($0.date, inSameDayAs: date) }
//    }
    
    private func hasEvent(on date: Date) -> Bool {
        allEvents.contains { calendar.isDate($0.date, inSameDayAs: date) } ||
        allMeasurementEvents.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func deleteEvents(at offsets: IndexSet, in dayEvents: [WorkoutEvent]) {
        let toDelete = offsets.map { dayEvents[$0] }
        for event in toDelete {
            modelContext.delete(event)
        }
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to delete events: \(error.localizedDescription)")
        }
    }

    private func moveEvents(from source: IndexSet, to destination: Int, in dayEvents: [WorkoutEvent]) {
        var reordered = dayEvents
        reordered.move(fromOffsets: source, toOffset: destination)

        // Reassign order just for this day's events
        for (index, event) in reordered.enumerated() {
            event.order = index
        }

        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to persist reordered events: \(error.localizedDescription)")
        }
    }
}

struct MeasurementEventView: View {
    let measurementEvent: MeasurementEvent

    var body: some View {
        List {
            Section(header: Text("Date").font(.headline)) {
                Text(measurementEvent.date, style: .date)
            }

            Section(header: Text("Measurements").font(.headline)) {
                ForEach(measurementEvent.measurements.sorted(by: { $0.type.rawValue < $1.type.rawValue })) { measurement in
                    HStack {
                        Text(measurement.type.rawValue)
                            .bold()
                        Spacer()
                        Text("\(measurement.value, specifier: "%.1f")")
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Measurements")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Preview

#Preview {
    CalendarView()
}
