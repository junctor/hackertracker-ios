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
    @EnvironmentObject var scrollBus: ScrollCommandBus
    @Environment(ThemeManager.self) private var themeManager
    var showBookmarks: Bool = true
    /// Number of items that would survive the current filter selection.
    /// Caller computes (uses the same .filters / .search pipeline the
    /// list view will render with) and passes it in — keeps the sheet
    /// agnostic about how counts are derived.
    var matchedCount: Int = 0
    /// Singular noun used in the live tally label ("event", "talk",
    /// etc.). Plural is auto-derived with a trailing s.
    var unitLabel: String = "event"
    @AppStorage(AppStorageKeys.filterMatchMode) private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw

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
                MatchModePickerRow(raw: $filterMatchModeRaw)
                FilterMatchCountLabel(count: matchedCount, unit: unitLabel)
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
            .themedNavTitle("Filters", themeManager)
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
                        scrollBus.send(.top)
                    }
                    .bold()
                }
            }
        }
    }
}

/// `Match  [ Any | All ]` segmented control. Sits at the top of the
/// filter list so users read the mode in the same place they see the
/// chips they're modifying. Persists via @AppStorage so heavy filter
/// users configure once and forget.
/// Shared `Match  [ Any | All ]` segmented control. Used by both
/// FiltersView (Schedule / All Content) and MerchSizeFilter so the
/// chrome stays identical across all filter sheets.
struct MatchModePickerRow: View {
    @Binding var raw: String
    @Environment(ThemeManager.self) private var themeManager
    var body: some View {
        HStack(spacing: 8) {
            Text("Match")
                .font(themeManager.subheadlineFont)
                .foregroundStyle(.secondary)
            Picker("Match", selection: $raw) {
                Text("Any").tag(FilterMatchMode.any.rawValue)
                Text("All").tag(FilterMatchMode.all.rawValue)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}

struct FilterRow: View {
    let id: Int
    let name: String
    let color: Color
    @EnvironmentObject var filters: Filters
    @Environment(ThemeManager.self) private var themeManager

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
                        .font(themeManager.subheadlineFont)
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

/// Small live tally label below the Match picker. Pluralizes the
/// supplied noun with a trailing s and renders muted so it doesn't
/// compete with the chips.
struct FilterMatchCountLabel: View {
    let count: Int
    let unit: String
    @Environment(ThemeManager.self) private var themeManager
    var body: some View {
        let plural = count == 1 ? unit : unit + "s"
        HStack(spacing: 4) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(themeManager.captionFont)
            Text("\(count) \(plural)")
                .font(themeManager.captionFont)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}
