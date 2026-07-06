//
//  EventsView.swift
//
//  Created by Caleb Kinney on 3/27/23.
//

import CoreData
import SwiftUI

struct EventsView: View {
    @EnvironmentObject var selected: SelectedConference
    @AppStorage(AppStorageKeys.showLocaltime) var showLocaltime: Bool = false
    @AppStorage(AppStorageKeys.show24hourtime) var show24hourtime: Bool = true
    @AppStorage(AppStorageKeys.showPastEvents) var showPastEvents: Bool = true
    @AppStorage(AppStorageKeys.showConflictAlert) var showConflictAlert: Bool = true
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject var scrollBus: ScrollCommandBus
    @EnvironmentObject var filters: Filters
    let dfu = DateFormatterUtility.shared
    var includeNav: Bool = true
    var navTitle: String = ""
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    /// Locally-stored custom events. Merged into the Schedule pipeline
    /// at query time via the `scheduleEvents` helper below — Firestore
    /// events stay on viewModel.events untouched.
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CustomEvent.beginTimestamp, ascending: true)])
    var customEvents: FetchedResults<CustomEvent>
    /// All event-scoped notes. Pulled once per render so the
    /// schedule filter can intersect against the set of target ids
    /// without touching Core Data inside the predicate closure.
    /// IDs of events / custom events that currently have a saved
    /// private Note attached. We don't use @FetchRequest here because
    /// SwiftUI's FetchRequest macro only reliably observes
    /// NSManagedObjectContextDidSave — NOT NSPersistentStoreRemoteChange,
    /// which is what fires when CloudKit imports Note rows from
    /// another device. NoteBlock's FetchRequest happened to work
    /// because it remounts on every detail screen push (fresh fetch);
    /// the schedule's FetchRequest mounts once and missed remote
    /// arrivals. Manual @State + dual-notification subscription is
    /// the reliable shape.
    @State private var noteEventIDsForScope: Set<Int32> = []
    /// Mirror for .content-kind notes. Schedule cells light up the
    /// pencil when EITHER the event id has a note OR the event's
    /// contentId has a note authored from the All-Content side.
    @State private var noteContentIDsForScope: Set<Int32> = []

    private func refreshNoteEventIDs() {
        let fr = NSFetchRequest<Note>(entityName: "Note")
        // One pass over all schedule-relevant kinds. Partition into
        // event/customEvent vs content based on each row's kind so the
        // cell can do an OR check on the env values it reads.
        fr.predicate = NSPredicate(
            format: "targetKind == %@ OR targetKind == %@ OR targetKind == %@",
            NoteKind.event.rawValue, NoteKind.customEvent.rawValue, NoteKind.content.rawValue
        )
        do {
            let rows = try viewContext.fetch(fr)
            var events: Set<Int32> = []
            var contents: Set<Int32> = []
            for r in rows {
                guard let kind = r.targetKind else { continue }
                if kind == NoteKind.content.rawValue {
                    contents.insert(r.targetID)
                } else {
                    events.insert(r.targetID)
                }
            }
            noteEventIDsForScope = events
            noteContentIDsForScope = contents
            Log.coreData.debug("EventsView notes events=\(events.count, privacy: .public) contents=\(contents.count, privacy: .public)")
        } catch {
            Log.coreData.error("EventsView note fetch failed: \(error as NSError, privacy: .public)")
        }
    }
    /// Drives the Add Custom Event modal sheet from the toolbar +
    /// button. Same state used by both the iPhone and iPad code paths.
    @State private var showingCustomEventForm: Bool = false

    /// User toggle (defaulting on) for whether custom events appear in
    /// the schedule at all. Lives next to the rest of the schedule
    /// state so its value is read inline with the synthesizer.
    @AppStorage(AppStorageKeys.showCustomEvents) private var showCustomEventsInSchedule: Bool = true
    /// Filter-chip composition mode. Read from the same
    /// AppStorage key the Filters sheet writes to.
    @AppStorage(AppStorageKeys.filterMatchMode) private var filterMatchModeRaw: String = FilterMatchMode.defaultRaw
    private var filterMatchMode: FilterMatchMode {
        FilterMatchMode(rawOrDefault: filterMatchModeRaw)
    }

    // MARK: Perf A: shared filter+search+group cache
    //
    // The filter -> search -> eventDayGroup pipeline used to be
    // recomputed inline at five call sites per body pass (filtered
    // count, two jump-to-day menus, two EventScrollViews). It's now
    // computed exactly once per relevant input change via the
    // `.task(id: schedulePipelineKey)` below (same shape as
    // SpeakersView's speakerTagIdsMap cache) and shared by every
    // call site in both the iPhone and iPad branches.

    /// Filtered + searched events grouped (and pre-sorted) by day.
    /// Feeds both EventScrollView instances.
    @State private var scheduleGrouped: [(key: String, value: [Event])] = []
    /// Day keys for the jump-to-day menus. Derived from the filtered
    /// (but NOT searched) pipeline — the menus have always ignored the
    /// search text, so preserve that.
    @State private var scheduleDayKeys: [String] = []
    /// Live count of events that survive the current filter +
    /// search selection. Driven into both the Filters sheet's
    /// tally label and any future toolbar-resident counter.
    @State private var scheduleFilteredCount: Int = 0

    /// Identity of every input the pipeline reads. When any of them
    /// change, `.task(id:)` re-runs `recomputeSchedulePipeline()`.
    private var schedulePipelineKey: Int {
        var hasher = Hasher()
        hasher.combine(selected.code)
        // Firestore events: id + timestamps + title + tags + location
        // cover the fields the pipeline and the rendered cells read.
        hasher.combine(viewModel.events.count)
        for e in viewModel.events {
            hasher.combine(e.id)
            hasher.combine(e.beginTimestamp)
            hasher.combine(e.endTimestamp)
            hasher.combine(e.title)
            hasher.combine(e.tagIds)
            hasher.combine(e.locationId)
        }
        // Custom events (synthesized into the schedule when enabled).
        hasher.combine(showCustomEventsInSchedule)
        hasher.combine(customEvents.count)
        for c in customEvents {
            hasher.combine(c.id)
            hasher.combine(c.beginTimestamp)
            hasher.combine(c.endTimestamp)
            hasher.combine(c.title)
            hasher.combine(c.colorHex)
            hasher.combine(c.eventDescription)
            hasher.combine(c.conferenceCodes as? [String] ?? [])
        }
        // Filter / search selection.
        hasher.combine(filters.filters)
        hasher.combine(filterMatchModeRaw)
        hasher.combine(debouncedSearch)
        hasher.combine(viewModel.tagtypes.count)
        hasher.combine(viewModel.speakers.count)
        // Bookmark identity (bookmark chip + toggles from cells).
        for b in bookmarks { hasher.combine(b.id) }
        // Notes ("Has Notes" chip).
        hasher.combine(noteEventIDsForScope)
        hasher.combine(noteContentIDsForScope)
        // Day-grouping timezone inputs.
        hasher.combine(showLocaltime)
        hasher.combine(viewModel.conference?.timezone)
        hasher.combine(dfu.tzGeneration)
        return hasher.finalize()
    }

    /// Runs the pipeline once and fans the results out to the cached
    /// @State copies above.
    private func recomputeSchedulePipeline() {
        let filtered = scheduleEvents
            .filters(typeIds: filters.filters, bookmarks: Set(bookmarks.map { $0.id }), tagTypes: viewModel.tagtypes, eventNoteIDs: noteEventIDsForScope, contentNoteIDs: noteContentIDsForScope, mode: filterMatchMode)
        scheduleDayKeys = filtered
            .eventDayGroup(showLocaltime: showLocaltime, conference: viewModel.conference)
            .map { $0.key }
        let searched = filtered.search(text: debouncedSearch, speakers: viewModel.speakers)
        scheduleFilteredCount = searched.count
        scheduleGrouped = searched.eventDayGroup(showLocaltime: showLocaltime, conference: viewModel.conference)
    }

    /// Firestore events + synthesized CustomEvents that target the
    /// currently-selected conference. The pipeline recompute reads
    /// this in place of viewModel.events so user-created rows flow
    /// through filters / search / eventDayGroup naturally.
    private var scheduleEvents: [Event] {
        guard showCustomEventsInSchedule else { return viewModel.events }
        let code = selected.code
        let synthesized = customEvents.compactMap { Event.from(custom: $0, conferenceCode: code) }
        return viewModel.events + synthesized
    }
    // @Binding var tappedScheduleTwice: Bool
    // @Binding var schedule: UUID

  @State private var eventDay = ""
  @State private var searchText = ""
  /// Phase 2: debounced copy used by the filter pipeline so we don't recompute
  /// filter+search+group on every keystroke.
  @State private var debouncedSearch = ""
  /// Polish: manual search affordance. `.searchable` in iOS 17 can't be hidden
  /// on initial load even with isPresented:false + .navigationBarDrawer or
  /// .toolbar placement -- the drawer renders anyway at scroll-top. So we
  /// roll our own: a magnifying glass in the nav bar toggles a thin inline
  /// search field that animates in above the schedule.
  @State private var isSearching = false
  @FocusState private var searchFocused: Bool

  //@Binding var filters: Set<Int>
  @State private var showFilters = false
  @State private var showEmergency = false
  @State private var showShareBookmarks = false
  @State private var showConflictAlertPopup = false
  /// iPad-only: identifies the content currently shown in the detail column
  /// of the schedule's NavigationSplitView. Nil = placeholder. Has no effect
  /// on iPhone (NavigationSplitView is bypassed there).
  @State private var ipadSelectedContentId: Int?
  /// iPad split: selected custom-event id for the right pane. Mutually
  /// exclusive with ipadSelectedContentId — setting one clears the
  /// other so the detail pane never shows stale state.
  @State private var ipadSelectedCustomEventId: UUID? = nil

  /// Polish: "Jump to Day" Menu. Now displayed as a floating button at the
  /// bottom-right of the schedule (see .overlay on the schedule VStack).
  /// The label here is just the icon; the surrounding floating-button chrome
  /// (size + Circle background) is applied at the use site so this builder
  /// can be reused for other placements if needed.
  @ViewBuilder private var jumpToDayMenu: some View {
      Menu {
          // Dates first (ascending; eventDayGroup already sorts that way),
          // then Top / Now / Next / Bottom.
          ForEach(scheduleDayKeys, id: \.self) { day in
              Button(day) {
                  eventDay = day
              }
          }
          Divider()
          Button {
              scrollBus.send(.top)
          } label: {
              Label("Top", systemImage: "arrow.up")
          }
          Button {
              scrollBus.send(.current)
          } label: {
              Label("Now", systemImage: "clock")
          }
          Button {
              scrollBus.send(.next)
          } label: {
              Label("Next", systemImage: "arrow.turn.right.down")
          }
          Button {
              scrollBus.send(.bottom)
          } label: {
              Label("Bottom", systemImage: "arrow.down")
          }
      } label: {
          Image(systemName: "arrow.up.arrow.down")
      }
      // Default .menuOrder is .priority, which reorders items so the most-
      // likely-tapped is closest to the trigger -- with a bottom-anchored
      // trigger that meant the date list rendered in reverse (descending).
      // .fixed forces declaration order.
      .menuOrder(.fixed)
  }

  /// Schedule body content used inside both the iPhone NavigationStack
  /// and the iPad NavigationSplitView sidebar. Contains the emergency
  /// banner, inline-search bar, EventScrollView, floating Filter +
  /// Jump-to-Day buttons, and the full toolbar.
  @ViewBuilder
  private var scheduleSidebar: some View {
    Group {
      if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documentsById[emergId] {
        NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body, color: themeManager.danger, systemImage: "exclamationmark.triangle.fill")) {
          CardView(systemImage: "exclamationmark.triangle.fill", text: doc.title, color: themeManager.danger, subtitle: "Tap for more details")
            .frame(height: 40)
            .cornerRadius(0)
        }
      }
      VStack(spacing: 0) {
        InlineSearchBar(placeholder: "Search title, speaker, or description", text: $searchText, isFocused: $searchFocused, visible: isSearching)
        EventScrollView(
          events: scheduleGrouped,
          dayTag: eventDay,
          showPastEvents: showPastEvents, includeNav: includeNav,
          showLocaltime: $showLocaltime
        )
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

          jumpToDayMenu
            .font(themeManager.title2Font)
            .foregroundStyle(.primary)
            .frame(width: 48, height: 48)
            .background(.regularMaterial, in: Circle())
            .accessibilityLabel("Jump to day")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
      }
      .themedBackground(themeManager)
      .navigationTitle(viewModel.conference?.name ?? "Schedule")
      .themedNavTitle(viewModel.conference?.name ?? "Schedule", themeManager)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Menu {
            NavigationLink(destination: ShareBookmarksView()) {
              Label("Share Schedule", systemImage: "qrcode")
            }
            Toggle(isOn: $showLocaltime) {
              Label("Display Localtime", systemImage: "clock")
            }
            .onChange(of: showLocaltime) { _, value in
              Log.ui.debug("EventsView showLocaltime=\(value)")
              if showLocaltime {
                dfu.update(tz: TimeZone.current)
              } else {
                ClockService.apply(conference: viewModel.conference, showLocaltime: false)
              }
            }
            Toggle(isOn: $show24hourtime) {
              Label("Display 24 Hour Time", systemImage: "calendar.badge.clock")
            }
            .onChange(of: show24hourtime) { _, value in
              Log.ui.debug("EventsView show24hourtime=\(value)")
            }
            Toggle(isOn: $showPastEvents) {
              Label("Show Past Events", systemImage: "calendar")
            }
            .onChange(of: showPastEvents) { _, value in
              Log.ui.debug("EventsView showPastEvents=\(value)")
              viewModel.showPastEvents = value
              scrollBus.send(.top)
            }
            .toggleStyle(.automatic)
          } label: {
            Image(systemName: "ellipsis")
          }
          .accessibilityLabel("Schedule options")
          if showConflictAlert, viewModel.bookmarkConflicts(bookmarks: bookmarks.map({Int($0.id)})) {
            Button {
              showConflictAlertPopup = true
            } label: {
              Image(systemName: "exclamationmark.triangle")
                .foregroundColor(themeManager.danger)
            }
            .accessibilityLabel("Bookmark schedule conflict")
            .accessibilityHint("Shows conflicting bookmarked events")
          }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button {
            showingCustomEventForm = true
          } label: {
            Image(systemName: "plus")
          }
          .accessibilityLabel("Add custom event")
          SearchToggleButton(isSearching: $isSearching, searchText: $searchText, isFocused: $searchFocused, searchLabel: "Search schedule")
        }
      }
      .task(id: searchText) {
        try? await Task.sleep(nanoseconds: 250_000_000)
        if !Task.isCancelled { debouncedSearch = searchText }
      }
      // Perf A: single recompute of the filter+search+group pipeline,
      // shared by the EventScrollView, jump-to-day menu, and the
      // filter sheet's matched count.
      .task(id: schedulePipelineKey) {
        recomputeSchedulePipeline()
      }
      .environment(\.noteEventIDs, noteEventIDsForScope)
      .environment(\.noteContentIDs, noteContentIDsForScope)
      .environment(\.bookmarkSnapshot, BookmarkSnapshot(bookmarkIds: bookmarks.map(\.id)))
      .onAppear { refreshNoteEventIDs() }
      .onReceive(NotificationCenter.default.publisher(
          for: .NSManagedObjectContextDidSave
      )) { _ in refreshNoteEventIDs() }
      .onReceive(NotificationCenter.default.publisher(
          for: .NSPersistentStoreRemoteChange
      )) { _ in refreshNoteEventIDs() }
      .sheet(isPresented: $showingCustomEventForm) {
        CustomEventFormView(existing: nil)
          .environment(\.managedObjectContext, viewContext)
      }
    }
  }

  var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility so SwiftUI
        // re-renders this view when the active timezone changes.
        let _ = dfu.tzGeneration
    if IPadAdaptive.isIPad && includeNav {
      // iPad: HStack-based custom split layout. Two sibling NavigationStacks
      // align naturally at the top -- no iOS 18 NavigationSplitView
      // floating-card sidebar styling, no Y misalignment between columns.
      // Each NavigationStack hosts its own toolbar so chrome stays consistent.
      HStack(spacing: 0) {
        NavigationStack {
          scheduleSidebar
        }
        .frame(width: IPadAdaptive.sidebarWidth)
        Divider()
        // iPad: keep a NavigationStack on the right pane so the sibling
        // pair preserves the layout symmetry iPadOS 18 uses to size the
        // safe-area top inset under the floating tab bar (the left
        // nav-title was disappearing otherwise). Hide *this* nav bar so
        // the empty header doesn't take visible space, and pad the top
        // so the event title isn't covered by the floating tab pill.
        // CustomEventDetailView's action buttons render inline on iPad.
        NavigationStack {
          Group {
            if let cid = ipadSelectedCustomEventId {
              CustomEventDetailView(eventID: cid)
                .id(cid)
            } else if let id = ipadSelectedContentId {
              ContentDetailView(contentId: id)
                .id(id)
            } else {
              ContentUnavailableView(
                "Select an Event",
                systemImage: "calendar",
                description: Text("Tap an event in the schedule to view details.")
              )
            }
          }
          .toolbar(.hidden, for: .navigationBar)
          .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 16)
          }
        }
      }
      .environment(\.iPadContentSelection, $ipadSelectedContentId)
      .environment(\.iPadCustomEventSelection, $ipadSelectedCustomEventId)
      .environment(\.noteEventIDs, noteEventIDsForScope)
      .environment(\.noteContentIDs, noteContentIDsForScope)
      .environment(\.bookmarkSnapshot, BookmarkSnapshot(bookmarkIds: bookmarks.map(\.id)))
      .onAppear { refreshNoteEventIDs() }
      .onReceive(NotificationCenter.default.publisher(
          for: .NSManagedObjectContextDidSave
      )) { _ in refreshNoteEventIDs() }
      .onReceive(NotificationCenter.default.publisher(
          for: .NSPersistentStoreRemoteChange
      )) { _ in refreshNoteEventIDs() }
      .sheet(isPresented: $showFilters) {
        EventFilters(
          tagtypes: viewModel.tagtypes.filter {
            $0.category == "content" && $0.isBrowsable == true
          },
          showFilters: $showFilters,
          matchedCount: scheduleFilteredCount,
          unitLabel: "event"
        )
      }
      .alert("Schedule Conflicts", isPresented: $showConflictAlertPopup) {
        Button("OK", role: .cancel) { }
        Button("Hide") {
          showConflictAlert = false
        }
      } message: {
        Text("Bookmarked events have conflicting times")
      }
    } else if includeNav {
      NavigationStack {
        scheduleSidebar
      }
      .sheet(isPresented: $showFilters) {
        EventFilters(
          tagtypes: viewModel.tagtypes.filter {
            $0.category == "content" && $0.isBrowsable == true
          },
          showFilters: $showFilters,
          matchedCount: scheduleFilteredCount,
          unitLabel: "event"
        )
      }
      .alert("Schedule Conflicts", isPresented: $showConflictAlertPopup) {
        Button("OK", role: .cancel) { }
        Button("Hide") {
          showConflictAlert = false
        }
      } message: {
        Text("Bookmarked events have conflicting times")
      }
      /*.sheet(isPresented: $showShareBookmarks) {
          QRCodeView(qrString: "hackertracker://\(viewModel.conference.code)/s?ids=\(bookmarks.map(\.id).joined(separator: ","))")
          Button("Dismiss") {
              showShareBookmarks.toggle()
          }
      } */
    } else {
      VStack(spacing: 0) {
        InlineSearchBar(placeholder: "Search title, speaker, or description", text: $searchText, isFocused: $searchFocused, visible: isSearching)
        EventScrollView(
          events: scheduleGrouped,
          dayTag: eventDay,
          showPastEvents: showPastEvents, includeNav: includeNav,
          // tappedScheduleTwice: $tappedScheduleTwice, schedule: $schedule,
          showLocaltime: $showLocaltime
        )
      }
        .navigationTitle(navTitle)
        .themedNavTitle(navTitle, themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    scrollBus.send(.top)
                } label: {
                  HStack {
                    Text("Top")
                    Image(systemName: "arrow.up")
                  }
                }
                  Button {
                      scrollBus.send(.current)
                  } label: {
                    HStack {
                      Text("Now")
                      Image(systemName: "clock")
                    }
                  }
                  Button {
                      scrollBus.send(.next)
                  } label: {
                    HStack {
                      Text("Next")
                      Image(systemName: "arrow.turn.right.down")
                    }
                  }
                  Button {
                      scrollBus.send(.bottom)
                  } label: {
                    HStack {
                      Text("Bottom")
                      Image(systemName: "arrow.down")
                    }
                  }
                  Divider()
              ForEach(scheduleDayKeys, id: \.self) { day in
                Button(day) {
                  eventDay = day
                }
              }

            } label: {
              Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Jump to day")
            SearchToggleButton(isSearching: $isSearching, searchText: $searchText, isFocused: $searchFocused, searchLabel: "Search schedule")
          }
        }
        .task(id: searchText) {
            // Phase 2: 250ms debounce so filter+search+group only runs once per pause.
            try? await Task.sleep(nanoseconds: 250_000_000)
            if !Task.isCancelled { debouncedSearch = searchText }
        }
        // Perf A: single recompute of the filter+search+group pipeline
        // for the embedded (no-nav) schedule variant.
        .task(id: schedulePipelineKey) {
            recomputeSchedulePipeline()
        }
        // Perf C: cells read bookmarks from the environment; publish
        // the snapshot for the embedded variant too.
        .environment(\.bookmarkSnapshot, BookmarkSnapshot(bookmarkIds: bookmarks.map(\.id)))
      .onChange(of: viewModel.conference) { _, con in
        Log.ui.debug("EventsView conference -> \(con?.name ?? "<nil>", privacy: .public)")
      }
    }
  }
}

struct EventScrollView: View {

    let events: [(key: String, value: [Event])]
    // let bookmarks: [Int32]
    let dayTag: String
    let showPastEvents: Bool
    let includeNav: Bool
    let dfu = DateFormatterUtility.shared
    // @Binding var tappedScheduleTwice: Bool
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var scrollBus: ScrollCommandBus
    @State var viewShowing = false
    @Binding var showLocaltime: Bool
    @State var eventDayGroup: [(key: String, value: [Event])] = []

    /// Phase 5a: events visible after the parent's filter/search pipeline.
    /// When this is empty we show a ContentUnavailableView instead of a
    /// blank scroll surface.
    private var visibleEvents: [(key: String, value: [Event])] {
        let now = Date()
        return showPastEvents ? events : events.compactMap { (key, day) in
            let upcoming = day.filter { now < $0.endTimestamp }
            return upcoming.isEmpty ? nil : (key, upcoming)
        }
    }

    /// ScrollCommandBus consumer. Performs the scroll for each command
    /// against this instance's proxy. Preserves the old ToTop fallback:
    /// when past events are hidden, "top" behaves like "current" since
    /// the true first event may not be rendered.
    private func handle(_ command: ScrollCommand, proxy: ScrollViewProxy) {
        // Day groups arrive pre-sorted by begin time (eventDayGroup),
        // so a flatMap walks events in chronological order.
        let ordered = events.flatMap { $0.value }
        switch command {
        case .top:
            guard showPastEvents else {
                handle(.current, proxy: proxy)
                return
            }
            if let e = ordered.first {
                withAnimation {
                    proxy.scrollTo(e.id, anchor: .top)
                }
            }
        case .bottom:
            if let e = ordered.last {
                withAnimation {
                    proxy.scrollTo(e.id)
                }
            }
        case .current:
            let curDate = Date()
            if let e = ordered.first(where: { curDate < $0.endTimestamp }) {
                withAnimation {
                    proxy.scrollTo(e.id, anchor: .top)
                }
            }
        case .next:
            let curDate = Date()
            if let e = ordered.first(where: { curDate < $0.beginTimestamp }) {
                withAnimation {
                    proxy.scrollTo(e.id, anchor: .top)
                }
            }
        }
    }

  var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility so SwiftUI
        // re-renders this view when the active timezone changes.
        let _ = dfu.tzGeneration
      /*
       VStack {
           ScrollView {
               ScrollViewReader { _ in
                   LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                       ForEach(self.contentGroup().sorted {
                           $0.key < $1.key
                       }, id: \.key) { char, content in
                           ContentData(char: char, content: content)
                       }
                   }
               }
               .listStyle(.plain)
           }
           .searchable(text: $searchText)
           .task(id: searchText) {
               try? await Task.sleep(nanoseconds: 250_000_000)
               if !Task.isCancelled { debouncedSearch = searchText }
           }
           .sheet(isPresented: $showFilters) {
             EventFilters(
               tagtypes: viewModel.tagtypes.filter {
                 $0.category == "content" && $0.isBrowsable == true
               },
               showFilters: $showFilters,
               matchedCount: scheduleFilteredCount,
               unitLabel: "event"
             )
           }
       }
       */
      VStack {
          // Phase 5a: pull-to-refresh + empty-state UX.
          ScrollView {
              if visibleEvents.isEmpty {
                  ContentUnavailableView(
                      "No Events",
                      systemImage: "calendar",
                      description: Text(showPastEvents
                          ? "Conference talks and sessions will appear here once scheduled."
                          : "Nothing upcoming. Try enabling \u{201C}Show Past Events\u{201D} or refresh.")
                  )
                  .padding(.top, 60)
              }
              ScrollViewReader { proxy in
                  LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                      ForEach(events, id: \.key) { weekday, dayEvents in
                          if showPastEvents || dayEvents.contains(where: {Date() < $0.endTimestamp}) {
                              EventData(
                                weekday: weekday, events: dayEvents, showPastEvents: showPastEvents
                              )
                              .id(weekday)
                          }
                      }
                  }
                  .listStyle(.plain)
                  // iPad: readable centered column for rows.
                  .iPadReadableContent()
                  .onChange(of: dayTag) { _, changedValue in 
                      withAnimation {
                          proxy.scrollTo(changedValue, anchor: .top)
                      }
                  }
                  .onReceive(scrollBus.subject) { command in
                      handle(command, proxy: proxy)
                  }
                  .onAppear {
                      viewShowing = true
                  }
                  .onDisappear {
                      viewShowing = false
                  }

              }

          }
          .refreshable {
              if let code = viewModel.conference?.code {
                  viewModel.fetchData(code: code)
              }
          }
      }
  }
}

struct EventData: View {
  let weekday: String
  let events: [Event]
  // let bookmarks: [Int32]
  let showPastEvents: Bool
  @Environment(ThemeManager.self) private var themeManager
  /// iPad split-view selection: when present, row taps set the binding
  /// instead of pushing a NavigationLink. iPhone passes no env value.
  @Environment(\.iPadContentSelection) private var iPadContentSelection
  @Environment(\.iPadCustomEventSelection) private var iPadCustomEventSelection

  var body: some View {
      Section(header: Text(weekday.uppercased())
        .font(themeManager.subheadlineFont)
        .padding(3)
        .frame(maxWidth: .infinity)
        // Phase 6 polish: match the toolbar's frosted material so the pinned
        // section header visually nests under the nav bar instead of
        // showing a hard gray seam.
        .background(.ultraThinMaterial)
    ) {
      Section {
        // Perf D: per-day arrays arrive pre-sorted from eventDayGroup;
        // capture "now" once instead of calling Date() per row.
        let now = Date()
        ForEach(events, id: \.id) { event in
          if showPastEvents || event.endTimestamp >= now {
            // Three row variants:
            //   1. iPad split + custom event -> set the custom-event
            //      selection (clears the content selection) so the
            //      right pane swaps in CustomEventDetailView. Without
            //      this branch we'd push onto the sidebar stack and
            //      cover the list instead.
            //   2. iPad split + Firestore event -> set the content
            //      selection (existing behavior).
            //   3. iPhone / non-split: NavigationLink as before, with
            //      a separate branch for custom vs Firestore so we
            //      route to the correct detail view.
            if let custSel = iPadCustomEventSelection,
               let contentSel = iPadContentSelection {
              if let cid = event.customEventID {
                Button {
                  contentSel.wrappedValue = nil
                  custSel.wrappedValue = cid
                } label: {
                  EventCell(event: event, showDay: false)
                    .id(event.id)
                    .foregroundColor(.primary)
                    .padding(1)
                }
                .buttonStyle(.plain)
              } else {
                Button {
                  custSel.wrappedValue = nil
                  contentSel.wrappedValue = event.contentId
                } label: {
                  EventCell(event: event, showDay: false)
                    .id(event.id)
                    .foregroundColor(.primary)
                    .padding(1)
                }
                .buttonStyle(.plain)
              }
            } else if let cid = event.customEventID {
              NavigationLink(destination: CustomEventDetailView(eventID: cid)) {
                EventCell(event: event, showDay: false)
                  .id(event.id)
                  .foregroundColor(.primary)
                  .padding(1)
              }
            } else if let sel = iPadContentSelection {
              Button {
                sel.wrappedValue = event.contentId
              } label: {
                EventCell(event: event, showDay: false)
                  .id(event.id)
                  .foregroundColor(.primary)
                  .padding(1)
              }
              .buttonStyle(.plain)
            } else {
              NavigationLink(destination: ContentDetailView(contentId:event.contentId)) {
                EventCell(event: event, showDay: false)
                  .id(event.id)
                  .foregroundColor(.primary)
                  .padding(1)
              }
            }
          }
        }
      }
      .listStyle(.plain)
    }.headerProminence(.increased)
  }
}
