//
//  ButtonNavBar.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-03.
//

import SwiftUI

struct ButtonNavBar: View {
    @Binding var selectedTab: String

    private let buttons: [NavButton] = [
        NavButton(label: "Workouts", systemImage: "list.bullet.rectangle"),
        NavButton(label: "Calendar", systemImage: "calendar"),
        NavButton(label: "Statistics", systemImage: "chart.xyaxis.line"),
        NavButton(label: "Settings", systemImage: "gearshape")
    ]
    
    struct NavButton: Identifiable {
        let id = UUID()
        let label: String
        let systemImage: String
    }

    var body: some View {
        HStack {
            ForEach(buttons) { button in
                Button(action: {
                    selectedTab = button.label
                    hapticClunk()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: button.systemImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                            .fontWeight(selectedTab == button.label ? .bold : .regular)
                            .foregroundColor(.black)
                        
                        Text(button.label)
                            .font(.caption)
                            .fontWeight(selectedTab == button.label ? .semibold : .regular)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity) 
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: 330)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color("Button").opacity(0.9))
                .shadow(radius: 2)
        )
    }

    private func hapticClunk() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    ButtonNavBar(selectedTab: .constant("Workouts"))
        .padding()
        .background(Color.gray.opacity(0.2))
}
