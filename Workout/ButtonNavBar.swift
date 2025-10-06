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
            NavButton(label: "Home", systemImage: "house.fill"),
            NavButton(label: "Calendar", systemImage: "calendar"),
            NavButton(label: "Stats", systemImage: "chart.xyaxis.line"),
            NavButton(label: "Settings", systemImage: "gearshape.fill")
        ]

        struct NavButton: Identifiable {
            let id = UUID()
            let label: String
            let systemImage: String
        }

        var body: some View {
            HStack(spacing: 20) {
                ForEach(buttons) { button in
                    Button(action: {
                        selectedTab = button.label
                        hapticClunk()
                    }) {
                        Image(systemName: button.systemImage)
                            .font(.largeTitle)
                            .foregroundColor(selectedTab == button.label ? .black : .gray)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
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
    ButtonNavBar(selectedTab: .constant("Home"))
        .padding()
        .background(Color.gray.opacity(0.2))
}
