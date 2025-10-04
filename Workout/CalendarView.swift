//
//  CalendarView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate: Date = Date()

    var body: some View {
        VStack {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical) 
            .padding()

            Text("Selected Date: \(selectedDate, formatter: dateFormatter)")
            
            Spacer()
        }
        .background(Color("Background"))
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}

#Preview {
    CalendarView()
}
