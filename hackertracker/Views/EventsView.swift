//
//  EventsView.swift
//
//  Created by Caleb Kinney on 3/27/23.
//

import SwiftUI

struct EventsView: View {
    @EnvironmentObject var selected: SelectedConference
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @AppStorage("show24hourtime") var show24hourtime: Bool = true
    @AppStorage("showPastEvents") var showPastEvents: Bool = true
    @AppStorage("showConflictAlert") var showConflictAlert: Bool = true
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var toTop: ToTop
    @EnvironmentObject var toBottom: ToBottom
    @EnvironmentObject var toCurrent: ToCurrent
    @EnvironmentObject var toNext: ToNext
    @EnvironmentObject var filters: Filters
    let dfu = DateFormatterUtility.shared
    var includeNav: Bool = true
    var navTitle: String = ""
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    // @Binding var tappedScheduleTwice: Bool
    // @Binding var schedule: UUID

  @State private var eventDay = ""
  @State private var searchText = ""
  /// Phase 2: debounced copy used by the filter pipeline so we don't recompute
  /// filter+search+group on every keystroke.
  @State private var debouncedSearch = ""
  //@Binding var filters: Set<Int>
  @State private var showFilters = false
  @State private var showEmergency = false
  @State private var showShareBookmarks = false
  @State private var showConflictAlertPopup = false

  var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility so SwiftUI
        // re-renders this view when the active timezone changes.
        let _ = dfu.tzGeneration
    if includeNav {
      NavigationStack {
        if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documents.first(where: {$0.id == emergId}) {
              NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body, color: ThemeColors.red, systemImage: "exclamationmark.triangle.fill")) {
                  CardView(systemImage: "exclamationmark.triangle.fill", text: doc.title, color: ThemeColors.red, subtitle: "Tap for more details")
                      .frame(height: 40)
                      .cornerRadius(0)
              }
        }
          
        EventScrollView(
          events:
            viewModel.events
            .filters(typeIds: filters.filters, bookmarks: bookmarks.map { $0.id }, tagTypes: viewModel.tagtypes)
            .search(text: debouncedSearch, speakers: viewModel.speakers)
            .eventDayGroup(
                showLocaltime: showLocaltime, conference: viewModel.conference
            ),
          dayTag: eventDay,
          showPastEvents: showPastEvents, includeNav: includeNav,
          showLocaltime: $showLocaltime
        )
        .navigationTitle(viewModel.conference?.name ?? "Schedule")
        // Phase 6 polish: compact (inline) title so the nav bar is a single
        // tight row instead of consuming a third of the screen with the
        // default `.large` display + frosted band.
        .navigationBarTitleDisplayMode(.inline)
        // Phase 6 polish: frosted nav bar so the title row reads cleanly when
        // content scrolls underneath instead of bleeding through transparent.
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
                // viewModel.showLocaltime = value
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
                  toTop.val = true
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
                          .foregroundColor(ThemeColors.red)
                  }
                  .accessibilityLabel("Bookmark schedule conflict")
                  .accessibilityHint("Shows conflicting bookmarked events")
              }
          }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        toTop.val = true
                    } label: {
                        HStack {
                            Text("Top")
                            Image(systemName: "arrow.up")
                        }
                    }
                    Button {
                        toCurrent.val = true
                    } label: {
                        HStack {
                            Text("Now")
                            Image(systemName: "clock")
                        }
                    }
                    Button {
                        toNext.val = true
                    } label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "arrow.turn.right.down")
                        }
                    }
                    Button {
                        toBottom.val = true
                    } label: {
                        HStack {
                            Text("Bottom")
                            Image(systemName: "arrow.down")
                        }
                    }
                    Divider()
                    ForEach(
                        viewModel.events.filters(typeIds: filters.filters, bookmarks: bookmarks.map { $0.id }, tagTypes: viewModel.tagtypes)
                            .eventDayGroup(showLocaltime: showLocaltime, conference: viewModel.conference), id: \.key
                    ) { day, _ in
                        Button(day) {
                            eventDay = day
                        }
                    }
                    
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Jump to day")

                Button {
                    showFilters.toggle()
                } label: {
                    Image(
                        systemName: filters.filters
                            .isEmpty
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill")
                }
                .accessibilityLabel(filters.filters.isEmpty ? "Filters" : "Filters active")
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .task(id: searchText) {
            // Phase 2: 250ms debounce so filter+search+group only runs once per pause.
            try? await Task.sleep(nanoseconds: 250_000_000)
            if !Task.isCancelled { debouncedSearch = searchText }
        }
      }
      .sheet(isPresented: $showFilters) {
        EventFilters(
          tagtypes: viewModel.tagtypes.filter {
            $0.category == "content" && $0.isBrowsable == true
          }, showFilters: $showFilters
        )
      }
      .alert("Schedule Conflicts", isPresented: $showConflictAlertPopup) {
          Button("OK", role: .cancel) {
          }
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
      VStack {
        EventScrollView(
          events:
            viewModel.events
            .filters(typeIds: filters.filters, bookmarks: bookmarks.map({$0.id}), tagTypes: viewModel.tagtypes)
            .search(text: debouncedSearch, speakers: viewModel.speakers).eventDayGroup(
                showLocaltime: showLocaltime, conference: viewModel.conference
            ),
          dayTag: eventDay,
          showPastEvents: showPastEvents, includeNav: includeNav,
          // tappedScheduleTwice: $tappedScheduleTwice, schedule: $schedule,
          showLocaltime: $showLocaltime
        )
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    toTop.val = true
                } label: {
                  HStack {
                    Text("Top")
                    Image(systemName: "arrow.up")
                  }
                }
                  Button {
                      toCurrent.val = true
                  } label: {
                    HStack {
                      Text("Now")
                      Image(systemName: "clock")
                    }
                  }
                  Button {
                      toNext.val = true
                  } label: {
                    HStack {
                      Text("Next")
                      Image(systemName: "arrow.turn.right.down")
                    }
                  }
                  Button {
                      toBottom.val = true
                  } label: {
                    HStack {
                      Text("Bottom")
                      Image(systemName: "arrow.down")
                    }
                  }
                  Divider()
              ForEach(
                viewModel.events.filters(typeIds: filters.filters, bookmarks: bookmarks.map({$0.id}), tagTypes: viewModel.tagtypes)
                    .eventDayGroup(showLocaltime: showLocaltime, conference: viewModel.conference), id: \.key
              ) { day, _ in
                Button(day) {
                  eventDay = day
                }
              }

            } label: {
              Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Jump to day")
          }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .task(id: searchText) {
            // Phase 2: 250ms debounce so filter+search+group only runs once per pause.
            try? await Task.sleep(nanoseconds: 250_000_000)
            if !Task.isCancelled { debouncedSearch = searchText }
        }
      }
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
    @EnvironmentObject var toTop: ToTop
    @EnvironmentObject var toCurrent: ToCurrent
    @EnvironmentObject var toBottom: ToBottom
    @EnvironmentObject var toNext: ToNext
    @State var viewShowing = false
    @Binding var showLocaltime: Bool
    @State var eventDayGroup: [(key: String, value: [Event])] = []

    /// Phase 5a: events visible after the parent's filter/search pipeline.
    /// When this is empty we show a ContentUnavailableView instead of a
    /// blank scroll surface.
    private var visibleEvents: [(key: String, value: [Event])] {
        showPastEvents ? events : events.compactMap { (key, day) in
            let upcoming = day.filter { Date() < $0.endTimestamp }
            return upcoming.isEmpty ? nil : (key, upcoming)
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
               }, showFilters: $showFilters
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
                  .onChange(of: dayTag) { _, changedValue in 
                      withAnimation {
                          proxy.scrollTo(changedValue, anchor: .top)
                      }
                  }
                  .onChange(of: toTop.val) { _, tapTop in 
                      guard tapTop else { return }
                      if tapTop, showPastEvents {
                          if let e = events.flatMap({$0.value}).sorted(by: {$0.beginTimestamp < $1.beginTimestamp}).first {
                              withAnimation {
                                  proxy.scrollTo(e.id, anchor: .top)
                              }
                          }
                          toTop.val = false
                      } else {
                          toTop.val = false
                          toCurrent.val = true
                      }
                      
                  }
                  .onChange(of: toBottom.val) { _, tapBottom in 
                      guard tapBottom else { return }
                      if tapBottom, let es = events.map({$0.value.sorted{$0.beginTimestamp < $1.beginTimestamp}}).last, let e = es.last {
                          withAnimation {
                              proxy.scrollTo(e.id)
                          }
                          toBottom.val = false
                      }
                  }
                  .onChange(of: toCurrent.val) { _, tapCurrent in 
                      guard tapCurrent else { return }
                      let curDate = Date()
                      // print("events: \(events.key)")
                      if tapCurrent, let es = events.flatMap({$0.value}).sorted(by: {$0.beginTimestamp < $1.beginTimestamp}).first(where: {curDate < $0.endTimestamp}) {
                          withAnimation {
                              proxy.scrollTo(es.id, anchor: .top)
                          }
                          toCurrent.val = false
                      }
                  }
                  .onChange(of: toNext.val) { _, tapNext in 
                      guard tapNext else { return }
                      let curDate = Date()
                      // print("events: \(events.key)")
                      if tapNext, let es = events.flatMap({$0.value}).sorted(by: {$0.beginTimestamp < $1.beginTimestamp}).first(where: {curDate < $0.beginTimestamp}) {
                          withAnimation {
                              proxy.scrollTo(es.id, anchor: .top)
                          }
                          toNext.val = false
                      }
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

  var body: some View {
      Section(header: Text(weekday.uppercased())
        .font(.subheadline)
        .padding(3)
        .frame(maxWidth: .infinity)
        // Phase 6 polish: match the toolbar's frosted material so the pinned
        // section header visually nests under the nav bar instead of
        // showing a hard gray seam.
        .background(.ultraThinMaterial)
    ) {
      Section {
        ForEach(
          events.sorted {
            $0.beginTimestamp < $1.beginTimestamp
          }, id: \.id
        ) { event in
          if showPastEvents || event.endTimestamp >= Date() {
              NavigationLink(destination: ContentDetailView(contentId:event.contentId)) {
              EventCell(event: event, showDay: false)
                      .id(event.id)
                      .foregroundColor(.primary)
                      .padding(1)
            }
          }
        }
      }
      .listStyle(.plain)
    }.headerProminence(.increased)
  }
}
