//
//  CalendarView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                Text("Calendar")
                    .font(.largeTitle)
                    .foregroundStyle(.black)
                
                Spacer()
                
            }
        }
    }
}

#Preview {
    CalendarView()
}
