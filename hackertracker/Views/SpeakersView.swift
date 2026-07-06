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
    @AppStorage(AppStorageKeys.filterMatchModeSpeakers) private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw
    @State private var searchText = ""

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var scrollToGroup: String.Element?
    @State private var lastJumpedGroup: String.Element?
    @State private var showFilters: Bool = false
    /// iPad-only: identifies the speaker currently shown in the detail column.
    @State private var ipadSelectedSpeakerId: Int?
    /// Precomputed `speaker.id → Set<Tag.id>` mapping. Rebuilt only
    /// when the underlying speakers / events / tagtypes lists change
    /// (see the `.task(id:)` modifier below). The filter pipeline and
    /// chip-pool computation both read from this dict so every render
    /// is O(speakers) instead of O(speakers × events).
    @State private var speakerTagIdsMap: [Int: Set<Int>] = [:]

    private var filterMatchMode: FilterMatchMode {
        FilterMatchMode(rawOrDefault: filterMatchModeRaw)
    }

    /// Set of tag IDs that *are* eligible to be surfaced as speaker
    /// chips / filter chips — browsable, category=="content", and
    /// not in the excluded-tagtype-labels set. The intersection
    /// guards against rogue tag IDs (events tagged with something
    /// from a non-displayed or filtered-out tagtype, e.g. "Tool")
    /// leaking into the speakers list.
    private var eligibleTagIds: Set<Int> {
        Set(
            viewModel.tagtypes
                .filter { $0.category == "content" && $0.isBrowsable }
                .filter { !SpeakerListConfig.excludedTagTypeLabels.contains($0.label) }
                .flatMap { $0.tags.map(\.id) }
        )
    }

    /// Rebuild the speaker→tagIds map. Only runs when the underlying
    /// data changes (events / speakers / tagtypes count), not on every
    /// keystroke or chip tap. O(speakers × avg-eventsPerSpeaker) once,
    /// then O(1) lookups everywhere downstream.
    private func rebuildSpeakerTagIdsMap() {
        let eligible = eligibleTagIds
        let eventsById = viewModel.eventsById
        var map: [Int: Set<Int>] = [:]
        for speaker in speakers {
            let tags = speaker.eventIds
                .compactMap { eventsById[$0]?.tagIds }
                .flatMap { $0 }
            map[speaker.id] = Set(tags).intersection(eligible)
        }
        speakerTagIdsMap = map
    }

    /// Apply search + the speakerFilters chip selection using the
    /// precomputed per-speaker tag-id map. O(speakers) per render
    /// instead of O(speakers × events). Search includes the speaker's
    /// event titles so a user looking up "BadgeLife" finds the
    /// speakers presenting that talk even if their name doesn't match.
    private var filteredSpeakers: [Speaker] {
        let searched = speakers.search(text: searchText, eventsById: viewModel.eventsById)
        let selected = speakerFilters.filters
        guard !selected.isEmpty else { return searched }
        return searched.filter { speaker in
            let st = speakerTagIdsMap[speaker.id] ?? []
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
    ///
    /// Computed directly from raw data (using `viewModel.eventsById`
    /// for O(1) lookups) rather than reading the precomputed
    /// `speakerTagIdsMap`, because the map is rebuilt asynchronously
    /// via `.task(id:)` and could be empty the first time the user
    /// presents the filter sheet — which produced an empty chip
    /// pool and a blank sheet. This computation only runs when the
    /// sheet actually opens, so the O(speakers × avgEvents) cost is
    /// one-shot, not per-render.
    private var availableTagTypes: [TagType] {
        let eventsById = viewModel.eventsById
        let speakerTagPool: Set<Int> = Set(
            speakers
                .flatMap { $0.eventIds }
                .compactMap { eventsById[$0]?.tagIds }
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
            InlineSearchBar(placeholder: "Search speakers", text: $searchText, isFocused: $searchFocused, visible: isSearching)
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
        // Rebuild the speaker→tagIds map only when one of the
        // underlying lists actually changes. Keystrokes + chip taps
        // run filteredSpeakers against the cached map (O(speakers))
        // rather than re-scanning viewModel.events for every speaker
        // on every render (O(speakers × events)).
        .task(id: "\(speakers.count)-\(viewModel.events.count)-\(viewModel.tagtypes.count)") {
            rebuildSpeakerTagIdsMap()
        }
        .navigationTitle("Speakers")
        .themedNavTitle("Speakers", themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                SearchToggleButton(isSearching: $isSearching, searchText: $searchText, isFocused: $searchFocused, searchLabel: "Search speakers")
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
                        SpeakerRow(speaker: speaker, themeColor: themeManager.carouselColor(index: speaker.id))
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                        SpeakerRow(speaker: speaker, themeColor: themeManager.carouselColor(index: speaker.id))
                    }
                    // Without .plain, NavigationLink tints every
                    // child view with the system accent color (system
                    // blue), which paints the row's tag-chip dots
                    // blue regardless of each tag's colorBackground.
                    // Matches the EventCell / ContentCell wrappers.
                    .buttonStyle(.plain)
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
    @AppStorage(AppStorageKeys.filterMatchModeSpeakers) private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw

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
