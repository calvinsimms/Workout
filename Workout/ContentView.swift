//
//  ContentView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-01.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.order, order: .forward) private var items: [Item]

    @State private var selectedTab: String = "Home"

    var body: some View {
        ZStack(alignment: .bottom) {
            
            Color("Background")
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(
                        items: items,
                        addItem: addItem,
                        deleteItems: deleteItems,
                        moveItems: moveItems
                    )
                }
                .tag("Home")

                NavigationStack {
                    CalendarView()
                }
                .tag("Calendar")

                NavigationStack {
                    StatsView()
                }
                .tag("Stats")

                NavigationStack {
                    SettingsView()
                }
                .tag("Settings")
            }
            .tabViewStyle(DefaultTabViewStyle())

            ButtonNavBar(selectedTab: $selectedTab)
                .padding(.bottom, 30)
        }
        .edgesIgnoringSafeArea(.bottom)
    }

    private func addItem() {
        withAnimation {
            let newOrder = (items.map { $0.order }.max() ?? -1) + 1
            let newItem = Item(title: "New Workout", order: newOrder)
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func moveItems(offsets: IndexSet, newOffset: Int) {
        withAnimation {
            var reordered = items
            reordered.move(fromOffsets: offsets, toOffset: newOffset)

            for (index, item) in reordered.enumerated() {
                item.order = index
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

