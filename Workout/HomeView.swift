//
//  HomeView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-10-04.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.editMode) private var editMode
    
    var items: [Item]
    var addItem: () -> Void
    var deleteItems: (IndexSet) -> Void
    var moveItems: (IndexSet, Int) -> Void

    var body: some View {
        VStack(spacing: 0){

            HStack {
                Button(action: {
                    withAnimation {
                        editMode?.wrappedValue = editMode?.wrappedValue == .active ? .inactive : .active
                    }
                }) {
                    Text("Edit")
                        .font(.system(.title3, weight: .bold))
                        .padding(10)
                        .background(Color("Button").opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(30)
                        .shadow(radius: 3)
                }
                Spacer()
                Button(action: addItem) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color("Button").opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 3)

                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Header
            HStack {
                Text("Workout")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            Divider()

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
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color("Background"))
                    .listRowSeparatorTint(.gray)
                    
                    
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
                
            }
            .listStyle(.plain)
            .environment(\.editMode, editMode)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 100)
            }
            
        }
        .background(Color("Background"))
    }
}



#Preview {
    HomeView(items: [], addItem: {}, deleteItems: { _ in },  moveItems: { _, _ in })
}
