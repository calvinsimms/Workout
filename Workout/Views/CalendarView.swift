//
//  CalendarView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI
import UIKit

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

// MARK: - Calendar View Model
class CalendarViewModel: ObservableObject {
    @Published var days: [Day] = []
    
    private let calendar = Calendar.current
    @Published var currentDate: Date
    
    init() {
        self.currentDate = Date()
        generateDays(for: currentDate)
    }
    
    func generateDays(for date: Date) {
        days.removeAll()
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        // Previous month days
        let prevMonth = calendar.date(byAdding: .month, value: -1, to: date)!
        let prevMonthRange = calendar.range(of: .day, in: .month, for: prevMonth)!
        for day in (prevMonthRange.count - (firstWeekday - 2))...prevMonthRange.count {
            if let date = calendar.date(bySetting: .day, value: day, of: prevMonth) {
                days.append(Day(date: date, isWithinCurrentMonth: false))
            }
        }
        
        // Current month days
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: date) {
                days.append(Day(date: date, isWithinCurrentMonth: true))
            }
        }
        
        // Next month padding (if needed to complete the grid)
        while days.count % 7 != 0 {
            if let nextMonthDate = calendar.date(byAdding: .day, value: 1, to: days.last!.date) {
                days.append(Day(date: nextMonthDate, isWithinCurrentMonth: false))
            }
        }
    }
    
    func moveMonth(by offset: Int) {
        if let newDate = calendar.date(byAdding: .month, value: offset, to: currentDate) {
            currentDate = newDate
            generateDays(for: currentDate)
        }
    }
    
    func monthYearText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentDate)
    }
}

// MARK: - Day Model
struct Day: Identifiable {
    let id = UUID()
    let date: Date
    let isWithinCurrentMonth: Bool
}

// MARK: - Custom Calendar Grid
struct CustomCalendarGrid: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var selectedDate: Date
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 5) {
            
            // Month header
            HStack {
                Text(viewModel.monthYearText())
                    .font(.title2)
                    .bold()
                Spacer()
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
                Button("<") { viewModel.moveMonth(by: -1) }
                    .font(.title)
                    .padding(.trailing, 20)
                Button(">") { viewModel.moveMonth(by: 1) }
                    .font(.title)
            }
            .padding(.horizontal, 20)
            .padding(.vertical)
            .foregroundStyle(.black)
            
            // Weekday labels
            HStack {
                ForEach(["Sun","Mon","Tue","Wed","Thu","Fri","Sat"], id: \.self) { day in
                    Text(day)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
            
            // Days grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.days) { day in
                    let hasEvent = sampleEvents.contains { event in
                        Calendar.current.isDate(event.date, inSameDayAs: day.date)
                    }
                    let isToday = Calendar.current.isDateInToday(day.date)

                    Text("\(Calendar.current.component(.day, from: day.date))")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            ZStack {
                                if isToday && !Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                }

                                if hasEvent && !Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                    Circle()
                                        .fill(Color("Button"))
                                }

                                if Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
                                    Circle()
                                        .fill(Color.black)
                                        .transition(.opacity)
                                }
                            }
                        )
                        .animation(.easeInOut(duration: 0.3), value: selectedDate)
                        .foregroundColor(day.isWithinCurrentMonth ?
                                         (Calendar.current.isDate(day.date, inSameDayAs: selectedDate) ? .white : .black)
                                         : .gray)
                        .contentShape(Rectangle())
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


// MARK: - Main CalendarView
struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    @State private var isAddExercisePresented = false
    @StateObject private var calendarVM = CalendarViewModel()

    private var eventsForSelectedDate: [Event] {
        sampleEvents.filter { event in
            Calendar.current.isDate(event.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                Image(systemName: "pencil")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding(10)
                    .background((Color("Button").opacity(0.9)))
                    .cornerRadius(30)
                    .shadow(radius: 2)
                    .padding(.bottom, 10)
                
                Spacer()
                
                Text("Calendar")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                
                Spacer()
                
                Button(action: {
                    isAddExercisePresented = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(10)
                        .background((Color("Button").opacity(0.9)))
                        .cornerRadius(30)
                        .shadow(radius: 2)
                        .padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 20)
            
            Divider()
            
            // MARK: - Custom Calendar
            CustomCalendarGrid(viewModel: calendarVM, selectedDate: $selectedDate)
            
            Divider()
        
            List {
                ForEach(eventsForSelectedDate) { event in
                    HStack {
                        Text(event.title)
                    }
                    .font(.system(.title2, weight: .bold))
                    .padding(.vertical, 10)
                    .listRowBackground(Color("Background"))
                }

                // Static row for "Add Exercise"
                Button(action: {
                    isAddExercisePresented = true
                }) {
                    HStack {
                        Text("Add Workout")
                            .font(.system(.title2, weight: .bold))
                            .padding(.vertical, 10)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
                .listRowBackground(Color("Background"))
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 100)
            }
            
        }
        .background(Color("Background"))
        .colorScheme(.light)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $isAddExercisePresented) {
            Text("Add Exercise View")
        }
    }
}

#Preview {
    CalendarView()
}
