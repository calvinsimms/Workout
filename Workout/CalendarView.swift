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

// MARK: - 
let sampleEvents: [Event] = [
    Event(date: Date(), title: "Chest"),
    Event(date: Date(), title: "Chest")
]

// MARK: - Calendar View
struct CalendarView: View {
    @State private var selectedDate: Date = Date()

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
            .accentColor(.black)
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
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color("Button").opacity(0.9))
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                        .cornerRadius(30)
                        .shadow(radius: 2)
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
                    .font(.system(.title, weight: .bold))
                    .padding(.vertical, 10)
                    .listRowBackground(Color("Background"))
                    .listRowSeparatorTint(.gray)
                }
                .listStyle(.plain)
            }
            Spacer()
        }
        .background(Color("Background").ignoresSafeArea())
        .colorScheme(.light)
        
    }
    
  
}

// MARK: - Preview
#Preview {
    CalendarView()
}
