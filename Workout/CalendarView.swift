//
//  CalendarView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

// MARK: - Event Model
struct Event: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
}

// MARK: - Sample Events
let sampleEvents: [Event] = [
    Event(date: Date(), title: "Chest")
]

// MARK: - Calendar View
struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    
    // Filter events for the selected day
    private var eventsForSelectedDate: [Event] {
        sampleEvents.filter { event in
            Calendar.current.isDate(event.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        VStack {

            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .accentColor(.blue)
            .padding()
     
            
            HStack {
                Text("Workouts on this day")
                    .font(.headline)
                    .padding(.leading, 30)
                
                Spacer()
                
                // Today Button
                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("Today")
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.trailing, 30)
                
            }
            
            // Event List
            if eventsForSelectedDate.isEmpty {
                Text("No workouts for this day")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(eventsForSelectedDate) { event in
                    HStack {
                        Text(event.title)
                    }
                    .font(.title)
                    .padding()
                  
                }
                .listStyle(.plain)
                
            }
            
            
            
            
            Spacer()
        }
        .background(Color("Background").ignoresSafeArea())
    }
    
    // MARK: - Date Formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}

// MARK: - Preview
#Preview {
    CalendarView()
}

