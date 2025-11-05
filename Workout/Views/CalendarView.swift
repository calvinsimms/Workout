//
//  CalendarView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//  Optimized 2025-11-02
//

import SwiftUI
import Foundation
import SwiftData

// MARK: - CalendarViewModel
@MainActor
final class CalendarViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var days: [Day] = []
    @Published var currentDate: Date
    @Published private(set) var events: [WorkoutEvent] = []

    private var eventCache: [Int: [WorkoutEvent]] = [:]

    private var monthlyCache: [String: [Int: [WorkoutEvent]]] = [:]

    // MARK: - Private

    private var context: ModelContext?
    
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.locale = .current
        return cal
    }()

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    // MARK: - Init

    init() {
        self.currentDate = Date()
        generateDays(for: currentDate)
    }

    func setContext(_ newContext: ModelContext) {
        guard context == nil else { return }
        context = newContext
        fetchEventsForCurrentMonth()
    }

    // MARK: - Visible Range Helpers

    private func monthKey(for date: Date) -> String {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }

    private func extendedMonthBounds(for date: Date) -> (start: Date, end: Date)? {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let start = calendar.date(byAdding: .month, value: -1, to: firstOfMonth),
              let end = calendar.date(byAdding: .month, value: 2, to: firstOfMonth) else {
            return nil
        }
        return (start, end)
    }

    private func dayKey(_ date: Date) -> Int {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return (comps.year ?? 0) * 10_000 + (comps.month ?? 0) * 100 + (comps.day ?? 0)
    }

    private func rebuildEventCache(from source: [WorkoutEvent]) {
        var newCache: [Int: [WorkoutEvent]] = [:]
        newCache.reserveCapacity(source.count)
        for ev in source {
            newCache[dayKey(ev.date), default: []].append(ev)
        }
        eventCache = newCache
    }

    // MARK: - Data Loading

    func fetchEventsForCurrentMonth() {
        guard let context else { return }

        let key = monthKey(for: currentDate)
        if let cached = monthlyCache[key] {
            eventCache = cached
            events = eventCache.values.flatMap { $0 }.sorted(by: { $0.date < $1.date })
            return
        }

        guard let (start, end) = extendedMonthBounds(for: currentDate) else {
            events = []
            eventCache.removeAll()
            return
        }

        let descriptor = FetchDescriptor<WorkoutEvent>(
            predicate: #Predicate { ev in
                ev.date >= start && ev.date < end
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            let fetched = try context.fetch(descriptor)
            events = fetched
            rebuildEventCache(from: fetched)
            monthlyCache[key] = eventCache
        } catch {
            print("⚠️ Failed to fetch events: \(error.localizedDescription)")
            events = []
            eventCache.removeAll()
        }
    }

    // MARK: - Calendar Grid Generation

    func generateDays(for date: Date) {
        days.removeAll(keepingCapacity: true)

        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let _ = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return }

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

    // MARK: - Month Navigation

    func moveMonth(by offset: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: offset, to: currentDate),
              !calendar.isDate(newDate, equalTo: currentDate, toGranularity: .month) else { return }

        currentDate = newDate
        generateDays(for: newDate)
        fetchEventsForCurrentMonth()
    }

    // MARK: - Display Helpers

    func monthYearText() -> String {
        Self.monthYearFormatter.string(from: currentDate)
    }

    // MARK: - Event Utilities

    func hasEvent(on date: Date) -> Bool {
        !(eventCache[dayKey(date)] ?? []).isEmpty
    }

    func events(on date: Date) -> [WorkoutEvent] {
        eventCache[dayKey(date)]?.sorted(by: { ($0.startTime ?? $0.date) < ($1.startTime ?? $1.date) }) ?? []
    }

    func deleteEvent(at offsets: IndexSet) {
        guard let context else { return }
        for index in offsets {
            let event = events[index]
            context.delete(event)
        }
        do {
            try context.save()
            monthlyCache.removeValue(forKey: monthKey(for: currentDate))
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

    func refreshForToday() {
        let today = Date()
        currentDate = today
        days.removeAll()
        generateDays(for: today)
        monthlyCache.removeAll()
        fetchEventsForCurrentMonth()
    }
}

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

    @ObservedObject var viewModel: CalendarViewModel
    @Binding var selectedDate: Date

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

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
            .padding(.horizontal, 10)
            .padding(.bottom, 5)

            // Grid
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(viewModel.days) { day in
                    let isSelected = Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(day.date)
                    let hasEvent = viewModel.hasEvent(on: day.date)

                    DayCellView(
                        day: day,
                        isSelected: isSelected,
                        isToday: isToday,
                        hasEvent: hasEvent
                    )
                    .onTapGesture {
                        withAnimation(.snappy) {
                            selectedDate = day.date

                            // If tapping a padding day, jump months
                            if !Calendar.current.isDate(day.date, equalTo: viewModel.currentDate, toGranularity: .month) {
                                viewModel.moveMonth(by:
                                    Calendar.current.compare(day.date, to: viewModel.currentDate, toGranularity: .month) == .orderedAscending ? -1 : 1
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)

            // Footer controls
            HStack {

                Button("Today") {
                    let today = Date()
                    selectedDate = today
                    viewModel.refreshForToday()
                }
                .font(.subheadline).bold()
                .buttonStyle(.glass)
                
                Spacer()
                
                GlassEffectContainer(spacing: 30.0) {
                    HStack {
                        Button {
                            viewModel.moveMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.glass)
                        
                        Button {
                            viewModel.moveMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))   
                        }
                        .buttonStyle(.glass)

                        
                    }
                }

            }
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
            .foregroundStyle(.black)
        }
    }
}

// MARK: - CalendarView

struct CalendarView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate: Date = Date()
    @State private var isAddWorkoutPresented = false

    // Prevent duplicate set-up work on re-appear
    @State private var didLoad = false
    @State private var refreshTask: Task<Void, Never>? = nil

    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                CustomCalendarGrid(
                    viewModel: viewModel,
                    selectedDate: $selectedDate
                )

                Divider()

                List {
                    let dayEvents = viewModel.events(on: selectedDate)

                    Section {
                        if dayEvents.isEmpty {
                            Text("No workouts planned today")
                                .foregroundColor(.gray)
                                .italic()
                                .padding(.vertical, 5)
                                .listRowBackground(Color("Background"))
                        } else {
                            ForEach(dayEvents) { event in
                                NavigationLink {
                                    WorkoutView(workoutTemplate: event.workoutTemplate ?? WorkoutTemplate(title: event.displayTitle))
                                } label: {
                                    Text(event.displayTitle)
                                        .font(.title3.bold())
                                        .foregroundColor(.black)
                                        .padding(.vertical, 5)
                                }
                                .listRowBackground(Color("Background"))
                            }
                            .onDelete { indexSet in
                                let allEvents = dayEvents
                                let globalOffsets = IndexSet(indexSet.compactMap { idx in
                                    viewModel.events.firstIndex { $0.id == allEvents[idx].id }
                                })
                                viewModel.deleteEvent(at: globalOffsets)
                            }
                            .onMove { source, destination in
                                viewModel.moveEvent(from: source, to: destination)
                            }
                        }
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
            .navigationTitle(Text(viewModel.monthYearText()))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .foregroundColor(.black)
                        .tint(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddWorkoutPresented = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $isAddWorkoutPresented, onDismiss: {
                viewModel.refreshForToday()
            }) {
                WorkoutSelectionView(defaultDate: selectedDate)
                    .presentationDetents([.large])
            }
            .onAppear {
                guard !didLoad else { return }
                viewModel.setContext(modelContext)
                scheduleMidnightRefresh()
                didLoad = true
            }
            .onDisappear {
                refreshTask?.cancel()
            }
            .task(id: viewModel.currentDate) {
                viewModel.fetchEventsForCurrentMonth()
            }
        }
    }

    // MARK: - Midnight Refresh (single loop, no recursion)
    private func scheduleMidnightRefresh() {
        refreshTask?.cancel()
        refreshTask = Task.detached(priority: .background) { [weak viewModel] in
            guard let viewModel else { return }
            while !Task.isCancelled {
                let now = Date()
                let cal = Calendar.current
                guard let nextMidnight = cal.nextDate(
                    after: now,
                    matching: DateComponents(hour: 0, minute: 0, second: 0),
                    matchingPolicy: .nextTime,
                    direction: .forward
                ) else {
                    try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                    continue
                }
                let interval = nextMidnight.timeIntervalSince(now)
                try? await Task.sleep(nanoseconds: UInt64(max(0, interval) * 1_000_000_000))
                await MainActor.run {
                    viewModel.refreshForToday()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
}
