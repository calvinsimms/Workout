//
//  ButtonNavBar.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-03.
//

import SwiftUI

struct ButtonNavBar: View {
    // Binding variable to keep track of the currently selected tab
    @Binding var selectedTab: String

    // Array of buttons to display in the navigation bar
    // Each button is represented by a NavButton struct
    private let buttons: [NavButton] = [
        NavButton(label: "Workouts", systemImage: "list.bullet.rectangle"),
        NavButton(label: "Calendar", systemImage: "calendar"),
        NavButton(label: "Statistics", systemImage: "chart.xyaxis.line"),
        NavButton(label: "Settings", systemImage: "gearshape")
    ]
    
    // Struct representing a single button in the navigation bar
    // Conforms to Identifiable so it can be used in ForEach
    struct NavButton: Identifiable {
        let id = UUID()
        let label: String
        let systemImage: String
    }

    var body: some View {
        HStack {
            ForEach(buttons) { button in // Loop through each NavButton
                Button(action: {
                    // When tapped, update the selected tab
                    selectedTab = button.label
                    // Trigger light haptic feedback
                    hapticClunk()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: button.systemImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                            // Bold icon if selected, otherwise regular
                            .fontWeight(selectedTab == button.label ? .bold : .regular)
                            .foregroundColor(.black)
                        
                        Text(button.label)
                            .font(.caption)
                            // Semi-bold text if selected, regular otherwise
                            .fontWeight(selectedTab == button.label ? .semibold : .regular)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        // Overall styling for the full HStack
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: 330)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color("Button").opacity(0.9))
                .shadow(radius: 2)
        )
    }

    // Helper function to trigger haptic feedback when a button is tapped
    private func hapticClunk() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred() // Trigger the haptic
    }
}

#Preview {
    ButtonNavBar(selectedTab: .constant("Workouts"))
}
