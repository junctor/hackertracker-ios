//
//  FiltersView.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/13/23.
//

import SwiftUI

struct EventFilters: View {
    let tagtypes: [TagType]
    @Binding var showFilters: Bool
    @EnvironmentObject var filters: Filters
    @EnvironmentObject var toTop: ToTop
    var showBookmarks: Bool = true
    
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        HStack(alignment: .center) {
            Button {
                filters.filters.removeAll()
            } label: {
                Image(systemName: "x.circle")
                Text("Clear")
            }
            Spacer()
            Text("Filters")
            Spacer()
            Button {
                showFilters = false
                toTop.val = true
            } label: {
                Text("Close")
                Image(systemName: "checkmark.circle")
            }
        }
        .padding(10)
            Divider()
            ScrollView {
                if showBookmarks {
                    FilterRow(id: 1337, name: "Bookmarks", color: ThemeColors.blue)
                }

                ForEach(tagtypes.sorted { $0.sortOrder < $1.sortOrder }) { tagtype in
                    Section(header: Text(tagtype.label)) {
                        LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 10) {
                            ForEach(tagtype.tags.sorted { $0.sortOrder < $1.sortOrder }) { tag in
                                FilterRow(id: tag.id, name: tag.label, color: Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple))
                            }
                        }
                    }
                }.headerProminence(.increased)
            }
            .listStyle(.plain)
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                }
            }
            .padding(5)
        }
    //}
}

struct FilterRow: View {
    let id: Int
    let name: String
    let color: Color
    @EnvironmentObject var filters: Filters

    var body: some View {
        
        Button(action: {
            if filters.filters.contains(id) {
                filters.filters.remove(id)
            } else {
                filters.filters.insert(id)
            }
            print("FiltersView: Current filters = \(filters.filters)")
        }) {
            VStack(alignment: .leading) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .padding(5)
                }
            }
            .foregroundColor(filters.filters.contains(id) ? .white : .primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(5)
            .background(filters.filters.contains(id) ? color : Color.clear)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(filters.filters.contains(id) ? Color.clear : color, lineWidth: 2))
        }

    }
}
