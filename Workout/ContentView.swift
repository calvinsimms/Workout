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
    @Query private var items: [Item]
    @Model
    final class Item {
        var title: String
        
        init(title: String) {
            self.title = title
        }
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack{
                
                HStack {
                    Button(action: {
                        // Add action
                    }) {
                        Text("Edit")
                            .font(.system(.title3, weight: .bold))
                            .padding(10)
                            .background(Color.black.opacity(0.1))
                            .foregroundColor(.black)
                            .cornerRadius(30)
                    }
                    Spacer()
                    Button(action: addItem) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.black.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                
                // Header
                HStack {
                    Text("Workout")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .foregroundColor(.black)
                    Spacer()
                }
                
                ZStack {
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                Text("Workout: \(item.title)")
                            } label: {
                                HStack {
                                    Text(item.title)
                                        .font(.system(.title, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 20)
                                .background(Color("Background"))
                                
                            }
                            .listRowBackground(Color("Background"))
                            .listRowSeparatorTint(.gray)
                            .listRowSeparator(.visible, edges: .all) 
                            
                        }
                        .onDelete(perform: deleteItems)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    .listStyle(.plain)

                    VStack {
                        Spacer()
                        
                        ButtonNavBar()
                    }
                }
                
                
                
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(title: "New Workout")
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
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
