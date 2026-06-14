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
        // Wrap in a NavigationStack so the sheet picks up the system's
        // rounded top corners + native toolbar treatment. The previous
        // custom HStack header sat flush against the sheet's sharp edge
        // and the Clear/Close buttons rendered as raw blue Text +
        // SF Symbol glyphs that didn't match Cancel/Save/Done in the
        // app's other modal forms.
        NavigationStack {
            ScrollView {
                if showBookmarks {
                    FilterRow(id: PseudoTagID.bookmarks, name: "Bookmarks", color: ThemeColors.blue)
                    FilterRow(id: PseudoTagID.customEvents, name: "Custom Events", color: .purple)
                    FilterRow(id: PseudoTagID.hasNotes, name: "Has Notes", color: .orange)
                }

                ForEach(tagtypes.sorted { $0.sortOrder < $1.sortOrder }) { tagtype in
                    Section { 
                        LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 10) {
                            ForEach(tagtype.tags.sorted { $0.sortOrder < $1.sortOrder }) { tag in
                                FilterRow(
                                    id: tag.id,
                                    name: tag.label,
                                    color: Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple)
                                )
                            }
                        }
                    } header: {
                        Text(tagtype.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .headerProminence(.increased)
            }
            .padding(.horizontal, 10)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Plain text button matching the Cancel/Save/Done pattern
                    // used by NoteEditorView, CustomEventFormView, etc.
                    // Disabled when there's nothing to clear so the user
                    // doesn't tap a no-op.
                    Button("Clear") {
                        filters.filters.removeAll()
                    }
                    .disabled(filters.filters.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showFilters = false
                        toTop.val = true
                    }
                    .bold()
                }
            }
        }
    }
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
            Log.ui.debug("FiltersView filters=\(filters.filters)")
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
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(filters.filters.contains(id) ? Color.clear : color, lineWidth: 2)
            )
        }
    }
}
