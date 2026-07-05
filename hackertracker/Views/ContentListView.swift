//
//  FAQListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import CoreData
import SwiftUI

struct ContentListView: View {
    var content: [Content]
    var title: String?
    @Environment(ThemeManager.self) private var themeManager
    @State private var searchText = ""
    /// Perf C: debounced mirror of `searchText`. contentGroup() reads
    /// this so the group/filter pipeline runs once per typing pause.
    @State private var debouncedSearch = ""
    /// Filter-chip composition mode. Mirrors EventsView so both
    /// lists honor the same user choice from the Filters sheet.
    @AppStorage("filterMatchMode") private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw
    private var filterMatchMode: FilterMatchMode {
        FilterMatchMode(rawOrDefault: filterMatchModeRaw)
    }
    @State private var showFilters = false
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var filters: Filters
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    /// Membership set of content ids that currently have a saved
    /// Note. Manual @State + remote-change observers rather than
    /// @FetchRequest so CloudKit-imported rows refresh the badge.
    @State private var noteContentIDsForScope: Set<Int32> = []

    private func refreshNoteContentIDs() {
        let fr = NSFetchRequest<Note>(entityName: "Note")
        // Fetch BOTH .content notes (direct) and .event notes
        // (indirect — reverse-map to the parent contentId so a note
        // authored from EventDetailView also lights up the All-Content
        // row). One fetch instead of two; partition by kind in code.
        fr.predicate = NSPredicate(
            format: "targetKind == %@ OR targetKind == %@",
            NoteKind.content.rawValue, NoteKind.event.rawValue
        )
        do {
            let rows = try viewContext.fetch(fr)
            var combined: Set<Int32> = []
            for r in rows {
                guard let kind = r.targetKind else { continue }
                if kind == NoteKind.content.rawValue {
                    combined.insert(r.targetID)
                } else if kind == NoteKind.event.rawValue {
                    // Reverse-lookup: which content does this event belong to?
                    if let event = viewModel.events.first(where: { Int32($0.id) == r.targetID }) {
                        combined.insert(Int32(event.contentId))
                    }
                }
            }
            noteContentIDsForScope = combined
            Log.coreData.debug("ContentListView noteContentIDsForScope count=\(noteContentIDsForScope.count, privacy: .public)")
        } catch {
            Log.coreData.error("ContentListView note fetch failed: \(error as NSError, privacy: .public)")
        }
    }

    // Polish: manual search affordance mirroring the schedule. The search field
    // is hidden on initial load and toggled by a magnifying glass in the
    // top-right toolbar.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool

    // Polish: jump-to-group plumbing. scrollToGroup feeds ScrollViewReader;
    // it resets to nil after each scroll so the same letter can be re-jumped.
    // lastJumpedGroup remembers the user's most-recent target so "Next Group"
    // advances correctly.
    @State private var scrollToGroup: String.Element?
    @State private var lastJumpedGroup: String.Element?
    /// iPad-only: identifies the content currently shown in the detail column.
    @State private var ipadSelectedContentId: Int?

    /// Grouped content computed once per body evaluation, shared by
    /// contentFilteredCount and grouped to avoid duplicate filtering.
    private var groupedContent: [String.Element: [Content]] {
        let bookmarkIds = Set(bookmarks.map(\.id))
        // Predicate composes search text + filter chips. The chips OR
        // with each other (matches any one keeps the row). Real tags
        // hit via tagIds.intersects; pseudo-tags 1337 (Bookmarks),
        // 1339 (Has Notes) hit via their dedicated membership sets.
        // Each category contributes a Bool? — non-nil only when at
        // least one chip from that category is selected. Compose by
        // mode: .any → OR (current default), .all → AND. Categories
        // without a chip selection don't constrain the result.
        let realTagIDs = filters.filters.subtracting(PseudoTagID.all)
        let useTags = !realTagIDs.isEmpty
        let useBookmarks = filters.filters.contains(PseudoTagID.bookmarks)
        let useHasNotes = filters.filters.contains(PseudoTagID.hasNotes)
        let mode = filterMatchMode
        return Dictionary(
            grouping: content.search(text: debouncedSearch).filter { c in
                if filters.filters.isEmpty { return true }
                let tagMatch: Bool? = useTags
                    ? c.tagIds.contains(where: { realTagIDs.contains($0) })
                    : nil
                let bookmarkMatch: Bool? = useBookmarks
                    ? c.sessions.contains(where: { bookmarkIds.contains(Int32($0.id)) })
                    : nil
                let hasNotesMatch: Bool? = useHasNotes
                    ? noteContentIDsForScope.contains(Int32(c.id))
                    : nil
                let checks = [tagMatch, bookmarkMatch, hasNotesMatch].compactMap { $0 }
                guard !checks.isEmpty else { return true }
                switch mode {
                case .any: return checks.contains(true)
                case .all: return checks.allSatisfy { $0 }
                }
            },
            by: { $0.title.lowercased().first ?? "-" }
        )
    }

    /// Number of Content rows surviving the current filter +
    /// search pipeline. Same shape as scheduleFilteredCount.
    private var contentFilteredCount: Int {
        groupedContent.values.reduce(0) { $0 + $1.count }
    }

    private var grouped: [(key: String.Element, value: [Content])] {
        groupedContent.sorted { $0.key < $1.key }
    }

    /// Inline search bar shown only when `isSearching` is true.
    @ViewBuilder private var inlineSearchBar: some View {
        if isSearching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search content title or description", text: $searchText)
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

    /// Toolbar button that toggles the inline search field.
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
        .accessibilityLabel(isSearching ? "Close search" : "Search content")
    }

    /// Floating bottom-right menu: jump to a letter group, plus
    /// Top / Next Group / Bottom shortcuts.
    @ViewBuilder private var jumpToGroupMenu: some View {
        Menu {
            // Direct letter jumps (ascending). Render in code order via
            // .menuOrder(.fixed) so the upward-opening menu doesn't reverse them.
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
            } label: {
                Label("Top", systemImage: "arrow.up")
            }
            Button {
                // Next letter after the most recent jump. If none yet, fall
                // back to the second group (or first, if there's only one).
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
            } label: {
                Label("Next Group", systemImage: "arrow.turn.right.down")
            }
            Button {
                if let last = grouped.last?.key {
                    scrollToGroup = last
                    lastJumpedGroup = last
                }
            } label: {
                Label("Bottom", systemImage: "arrow.down")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }

    /// Content body used inside both the iPhone NavigationStack and the
    /// iPad NavigationSplitView sidebar.
    @ViewBuilder
    private var contentSidebar: some View {
        VStack(spacing: 0) {
            inlineSearchBar
            ScrollView {
                if grouped.isEmpty {
                    if searchText.isEmpty && filters.filters.isEmpty {
                        ContentUnavailableView(
                            "No Content",
                            systemImage: "doc.text",
                            description: Text("Talks, workshops, and other content will appear here once published.")
                        )
                        .padding(.top, 60)
                    } else if !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .padding(.top, 60)
                    } else {
                        ContentUnavailableView(
                            "No Matches",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("No items match the current filters.")
                        )
                        .padding(.top, 60)
                    }
                } else {
                    ScrollViewReader { proxy in
                        LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                            ForEach(grouped, id: \.key) { char, content in
                                ContentData(char: char, content: content)
                                    .id(char)
                            }
                        }
                        .onChange(of: scrollToGroup) { _, target in
                            guard let target else { return }
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                            DispatchQueue.main.async { scrollToGroup = nil }
                        }
                    }
                    .listStyle(.plain)
                    .iPadReadableContent()
                }
            }
            .refreshable {
                if let code = viewModel.conference?.code {
                    viewModel.fetchData(code: code)
                }
            }
            .sheet(isPresented: $showFilters) {
              EventFilters(
                tagtypes: viewModel.tagtypes.filter {
                  $0.category == "content" && $0.isBrowsable == true
                },
                showFilters: $showFilters,
                matchedCount: contentFilteredCount,
                unitLabel: "talk"
              )
            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                Button {
                    showFilters.toggle()
                } label: {
                    Image(systemName: filters.filters.isEmpty
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                        .font(themeManager.title2Font)
                        .frame(width: 48, height: 48)
                        .background(.regularMaterial, in: Circle())
                }
                .tint(.primary)
                .accessibilityLabel(filters.filters.isEmpty ? "Filters" : "Filters active")

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
        .navigationTitle(title ?? "All Content")
        .themedNavTitle(title ?? "All Content", themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                searchToggleButton
            }
        }
        .task(id: searchText) {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if !Task.isCancelled { debouncedSearch = searchText }
        }
        .environment(\.noteContentIDs, noteContentIDsForScope)
        .onAppear { refreshNoteContentIDs() }
        .onReceive(NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave
        )) { _ in refreshNoteContentIDs() }
        .onReceive(NotificationCenter.default.publisher(
            for: .NSPersistentStoreRemoteChange
        )) { _ in refreshNoteContentIDs() }
        .themedBackground(themeManager)
        .analyticsScreen(name: "ContentListView")
    }

    var body: some View {
        if IPadAdaptive.isIPad {
            HStack(spacing: 0) {
                contentSidebar
                    .frame(width: IPadAdaptive.sidebarWidth)
                Divider()
                Group {
                    if let id = ipadSelectedContentId {
                        ContentDetailView(contentId: id)
                            .id(id)
                    } else {
                        ContentUnavailableView(
                            "Select Content",
                            systemImage: "doc.text",
                            description: Text("Tap an item in the list to view details.")
                        )
                    }
                }
            }
            .environment(\.iPadContentSelection, $ipadSelectedContentId)
        } else {
            contentSidebar
        }
    }
}

struct ContentData: View {
    let char: String.Element
    let content: [Content]
    @EnvironmentObject var theme: Theme
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    /// iPad split-view: row taps update detail column instead of pushing.
    @Environment(\.iPadContentSelection) private var iPadContentSelection

    var body: some View {
        let contentRowBookmarks = bookmarks.map { $0.id }
        Section(header: Text(String(char.uppercased()))
            .font(themeManager.subheadlineFont)
            .padding(3)
            .frame(maxWidth: .infinity)
            // Phase 6 polish: match the toolbar's frosted material.
            .background(.ultraThinMaterial)
        ) {
            ForEach(content, id: \.id) { item in
                if let sel = iPadContentSelection {
                    Button {
                        sel.wrappedValue = item.id
                    } label: {
                        ContentCell(content: item, bookmarks: contentRowBookmarks, showDay: false)
                            .padding(1)
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(destination: ContentDetailView(contentId: item.id)) {
                        ContentCell(content: item, bookmarks: contentRowBookmarks, showDay: false)
                            .padding(1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .listStyle(.plain)
    }
}

struct ContentRow: View {
    let item: Content
    let themeColor: Color
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        HStack {
            Rectangle().fill(themeColor)
                .frame(width: 6)
                .frame(maxHeight: .infinity)
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(themeManager.headingFont)
                    .foregroundColor(.primary)
            }
        }
    }
}

/* struct ContentListView_Previews: PreviewProvider {
    static var previews: some View {
        //ContentListView()
    }
} */
