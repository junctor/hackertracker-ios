//
//  FiltersView.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/13/23.
//

import SwiftUI

struct EventFilters: View {
    let tagtypes: [TagType]
    // let types: [Int: EventType]
    @Binding var showFilters: Bool
    @Binding var filters: Set<Int>
    
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                FilterRow(id: 1337, name: "Bookmarks", color: ThemeColors.blue, filters: $filters)

                ForEach(tagtypes.sorted { $0.sortOrder < $1.sortOrder }) { tagtype in
                    Section(header: Text(tagtype.label)) {
                        LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 10) {
                            ForEach(tagtype.tags.sorted { $0.sortOrder < $1.sortOrder }) { tag in
                                FilterRow(id: tag.id, name: tag.label, color: Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple), filters: $filters)
                            }
                        }
                    }
                }.headerProminence(.increased)
            }
            .listStyle(.plain)
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        filters.removeAll()
                    }
                    Button("Close") {
                        showFilters = false
                    }
                }
            }
            .padding(5)
        }
    }
}

struct FilterRow: View {
    let id: Int
    let name: String
    let color: Color
    @Binding var filters: Set<Int>

    var body: some View {
        if !filters.contains(id) {
            VStack(alignment: .leading) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .padding(5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(5)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 2))
            .onTapGesture {
                print("Filters (tap): \(filters)")
                if filters.contains(id) {
                    filters.remove(id)
                } else {
                    filters.insert(id)
                }
            }
        } else {
            VStack(alignment: .leading) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .padding(5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(5)
            .background(color)
            .cornerRadius(10)
            .onTapGesture {
                if filters.contains(id) {
                    filters.remove(id)
                } else {
                    filters.insert(id)
                }
            }
        }
    }
}
