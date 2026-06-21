//
//  SpeakersView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI

struct SpeakersView: View {
    var speakers: [Speaker]
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject var speakerFilters: SpeakerFiltersStore
    @AppStorage("filterMatchModeSpeakers") private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw
    @State private var searchText = ""

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var scrollToGroup: String.Element?
    @State private var lastJumpedGroup: String.Element?
    @State private var showFilters: Bool = false
    /// iPad-only: identifies the speaker currently shown in the detail column.
    @State private var ipadSelectedSpeakerId: Int?

    private var filterMatchMode: FilterMatchMode {
        FilterMatchMode(rawOrDefault: filterMatchModeRaw)
    }

    /// Tag IDs from tagtypes intentionally hidden from the speakers
    /// list (`SpeakerListConfig.excludedTagTypeLabels`). Cached as a
    /// computed property so the filter pipeline and the chip-pool
    /// computation both pull from the same exclusion set.
    private var excludedTagIds: Set<Int> {
        Set(
            viewModel.tagtypes
                .filter { SpeakerListConfig.excludedTagTypeLabels.contains($0.label) }
                .flatMap { $0.tags.map(\.id) }
        )
    }

    /// Rolls a speaker's events up into their unique tag IDs minus
    /// the excluded tagtypes. Same logic as SpeakerRow's chip strip
    /// — keep them aligned so the filter selects on exactly what the
    /// chips display.
    private func tagIds(for speaker: Speaker) -> Set<Int> {
        let mine = viewModel.events.filter { speaker.eventIds.contains($0.id) }
        return Set(mine.flatMap(\.tagIds)).subtracting(excludedTagIds)
    }

    /// Apply search + the speakerFilters chip selection. Same Any/All
    /// semantics as the schedule's filter pipeline so behavior reads
    /// the same way to a user toggling between tabs.
    private var filteredSpeakers: [Speaker] {
        let searched = speakers.search(text: searchText)
        let selected = speakerFilters.filters
        guard !selected.isEmpty else { return searched }
        return searched.filter { speaker in
            let st = tagIds(for: speaker)
            switch filterMatchMode {
            case .any: return !st.isDisjoint(with: selected)
            case .all: return selected.isSubset(of: st)
            }
        }
    }

    /// Subset of conference tagtypes that actually appear in this
    /// speakers list. Smaller pool than the schedule's filter because
    /// speakers are bounded by their participation — we only show
    /// chips for tags at least one speaker is connected to.
    private var availableTagTypes: [TagType] {
        let speakerTagPool: Set<Int> = Set(
            speakers
                .flatMap { $0.eventIds }
                .compactMap { id in viewModel.events.first(where: { $0.id == id })?.tagIds }
                .flatMap { $0 }
        )
        return viewModel.tagtypes
            .filter { $0.category == "content" && $0.isBrowsable }
            .filter { !SpeakerListConfig.excludedTagTypeLabels.contains($0.label) }
            .compactMap { tagtype in
                var copy = tagtype
                copy.tags = tagtype.tags.filter { speakerTagPool.contains($0.id) }
                return copy.tags.isEmpty ? nil : copy
            }
    }

    private var grouped: [(key: String.Element, value: [Speaker])] {
        Dictionary(grouping: filteredSpeakers,
                   by: { $0.name.lowercased().first ?? "-" })
            .sorted { $0.key < $1.key }
    }

    @ViewBuilder private var inlineSearchBar: some View {
        if isSearching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search speakers", text: $searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search text")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder private var searchToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearching.toggle()
            }
            if isSearching {
                searchFocused = true
            } else {
                searchText = ""
            }
        } label: {
            Image(systemName: isSearching ? "xmark.circle" : "magnifyingglass")
        }
        .accessibilityLabel(isSearching ? "Close search" : "Search speakers")
    }

    @ViewBuilder private var jumpToGroupMenu: some View {
        Menu {
            ForEach(grouped, id: \.key) { char, _ in
                Button(String(char).uppercased()) {
                    scrollToGroup = char
                    lastJumpedGroup = char
                }
            }
            Divider()
            Button {
                if let first = grouped.first?.key {
                    scrollToGroup = first
                    lastJumpedGroup = first
                }
            } label: { Label("Top", systemImage: "arrow.up") }
            Button {
                if let last = lastJumpedGroup,
                   let idx = grouped.firstIndex(where: { $0.key == last }),
                   idx + 1 < grouped.count {
                    let next = grouped[idx + 1].key
                    scrollToGroup = next
                    lastJumpedGroup = next
                } else if let fallback = grouped.dropFirst().first?.key ?? grouped.first?.key {
                    scrollToGroup = fallback
                    lastJumpedGroup = fallback
                }
            } label: { Label("Next Group", systemImage: "arrow.turn.right.down") }
            Button {
                if let last = grouped.last?.key {
                    scrollToGroup = last
                    lastJumpedGroup = last
                }
            } label: { Label("Bottom", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }

    @ViewBuilder
    private var speakerSidebar: some View {
        VStack(spacing: 0) {
            inlineSearchBar
            ScrollView {
                if grouped.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "No Speakers",
                            systemImage: "person.2",
                            description: Text("Conference presenters will appear here once they're announced.")
                        )
                        .padding(.top, 60)
                    } else {
                        ContentUnavailableView.search(text: searchText)
                            .padding(.top, 60)
                    }
                } else {
                    ScrollViewReader { proxy in
                        LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                            ForEach(grouped, id: \.key) { char, speakers in
                                SpeakerData(char: char, speakers: speakers)
                                    .id(char)
                            }
                        }
                        .onChange(of: scrollToGroup) { _, target in
                            guard let target else { return }
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                            DispatchQueue.main.async { scrollToGroup = nil }
                        }
                    }
                    .iPadReadableContent()
                }
            }
            .refreshable {
                if let code = viewModel.conference?.code {
                    viewModel.fetchData(code: code)
                }
            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                // Filter circle on the leading side, mirroring
                // Schedule's affordance placement.
                Button {
                    showFilters.toggle()
                } label: {
                    Image(systemName: speakerFilters.filters.isEmpty
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                        .font(themeManager.title2Font)
                        .frame(width: 48, height: 48)
                        .background(.regularMaterial, in: Circle())
                }
                .tint(.primary)
                .accessibilityLabel(speakerFilters.filters.isEmpty ? "Filters" : "Filters active")

                Spacer()

                jumpToGroupMenu
                    .font(themeManager.title2Font)
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(.regularMaterial, in: Circle())
                    .accessibilityLabel("Jump to group")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .sheet(isPresented: $showFilters) {
            SpeakerFiltersSheet(
                tagtypes: availableTagTypes,
                showFilters: $showFilters,
                matchedCount: filteredSpeakers.count
            )
        }
        .navigationTitle("Speakers")
        .themedNavTitle("Speakers", themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                searchToggleButton
            }
        }
        .analyticsScreen(name: "SpeakersView")
    }

    var body: some View {
        if IPadAdaptive.isIPad {
            HStack(spacing: 0) {
                speakerSidebar
                    .frame(width: IPadAdaptive.sidebarWidth)
                Divider()
                Group {
                    if let id = ipadSelectedSpeakerId {
                        SpeakerDetailView(id: id)
                            .id(id)
                    } else {
                        ContentUnavailableView(
                            "Select a Speaker",
                            systemImage: "person.2",
                            description: Text("Tap a speaker in the list to view their details.")
                        )
                    }
                }
            }
            .environment(\.iPadSpeakerSelection, $ipadSelectedSpeakerId)
        } else {
            speakerSidebar
        }
    }
}

struct SpeakerData: View {
    let char: String.Element
    let speakers: [Speaker]
    @EnvironmentObject var theme: Theme
    @Environment(ThemeManager.self) private var themeManager
    /// iPad split-view: row taps update detail column instead of pushing.
    @Environment(\.iPadSpeakerSelection) private var iPadSpeakerSelection

    var body: some View {
        Section(header: Text(String(char.uppercased()))
            .font(themeManager.subheadlineFont)
            .padding(1)
            .frame(maxWidth: .infinity)
            // Phase 6 polish: match the toolbar's frosted material.
            .background(.ultraThinMaterial)
        ) {
            ForEach(speakers, id: \.id) { speaker in
                if let sel = iPadSpeakerSelection {
                    Button {
                        sel.wrappedValue = speaker.id
                    } label: {
                        SpeakerRow(speaker: speaker, themeColor: theme.carousel())
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                        SpeakerRow(speaker: speaker, themeColor: theme.carousel())
                    }
                }
            }
        }
    }
}

struct SpeakersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpeakersView(speakers: []).preferredColorScheme(.dark)
        }
    }
}

/// Filter sheet for the Speakers list. Mirrors the chrome of
/// `EventFilters` (Match Any/All picker + live tally + tagtype-
/// grouped chip grid + Clear/Done toolbar buttons) so users see the
/// same shape they already know from Schedule. Differences:
///
/// - Reads `SpeakerFiltersStore` instead of `Filters`, so toggling a
///   chip here doesn't bleed into Schedule / All Content selections.
/// - Persists Match mode under "filterMatchModeSpeakers" so the
///   speakers list mode is independent from the schedule's.
/// - No pseudo-tag chips. Bookmarks don't apply to speakers and
///   notes aren't authored on speakers at present — re-add when
///   either becomes meaningful for this list.
/// - Tag pool is already pre-filtered upstream by `SpeakersView` to
///   only the tags at least one visible speaker is connected to.
struct SpeakerFiltersSheet: View {
    let tagtypes: [TagType]
    @Binding var showFilters: Bool
    @EnvironmentObject var speakerFilters: SpeakerFiltersStore
    @Environment(ThemeManager.self) private var themeManager
    /// Same shape as EventFilters' matchedCount — caller computes
    /// using the same filter pipeline so the displayed tally is the
    /// row count the list will render.
    var matchedCount: Int = 0
    @AppStorage("filterMatchModeSpeakers") private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw

    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                MatchModePickerRow(raw: $filterMatchModeRaw)
                FilterMatchCountLabel(count: matchedCount, unit: "speaker")

                ForEach(tagtypes.sorted { $0.sortOrder < $1.sortOrder }) { tagtype in
                    Section {
                        LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 10) {
                            ForEach(tagtype.tags.sorted { $0.sortOrder < $1.sortOrder }) { tag in
                                SpeakerFilterRow(
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
                    Button("Clear") {
                        speakerFilters.filters.removeAll()
                    }
                    .disabled(speakerFilters.filters.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showFilters = false
                    }
                    .bold()
                }
            }
        }
    }
}

/// Speaker-list flavored copy of FilterRow. Same chip styling as the
/// schedule's row but writes to `SpeakerFiltersStore`. A separate
/// struct (vs. parameterizing FilterRow with a generic store) keeps
/// EnvironmentObject typing clean — both Filters and
/// SpeakerFiltersStore can be present in the env without one chip
/// row picking the wrong store.
struct SpeakerFilterRow: View {
    let id: Int
    let name: String
    let color: Color
    @EnvironmentObject var speakerFilters: SpeakerFiltersStore
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Button(action: {
            if speakerFilters.filters.contains(id) {
                speakerFilters.filters.remove(id)
            } else {
                speakerFilters.filters.insert(id)
            }
            Log.ui.debug("SpeakerFilters=\(speakerFilters.filters)")
        }) {
            VStack(alignment: .leading) {
                HStack {
                    Text(name)
                        .font(themeManager.subheadlineFont)
                        .padding(5)
                }
            }
            .foregroundColor(speakerFilters.filters.contains(id) ? .white : .primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(5)
            .background(speakerFilters.filters.contains(id) ? color : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
