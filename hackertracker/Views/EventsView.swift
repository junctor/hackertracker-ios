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
    @EnvironmentObject var viewModel: InfoViewModel
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
  //@Binding var filters: Set<Int>
  @State private var showFilters = false

  var body: some View {
    if includeNav {
      NavigationStack {
        EventScrollView(
          events:
            viewModel.events
            .filters(typeIds: filters.filters, bookmarks: bookmarks.map { $0.id }, tagTypes: viewModel.tagtypes)
            .search(text: searchText)
            .eventDayGroup(
                showLocaltime: showLocaltime, conference: viewModel.conference
            ),
          dayTag: eventDay,
          showPastEvents: showPastEvents, includeNav: includeNav,
          showLocaltime: $showLocaltime
        )
        .navigationTitle(viewModel.conference?.name ?? "Schedule")
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarLeading) {
            Menu {
              Toggle(isOn: $showLocaltime) {
                Label("Display Localtime", systemImage: "clock")
              }
              .onChange(of: showLocaltime) { value in
                print("EventsView: Changing to showLocaltime = \(value)")
                // viewModel.showLocaltime = value
                if showLocaltime {
                  dfu.update(tz: TimeZone.current)
                } else {
                  dfu.update(
                    tz: TimeZone(identifier: viewModel.conference?.timezone ?? "America/Los_Angeles"))
                }
              }
                Toggle(isOn: $show24hourtime) {
                  Label("Display 24 Hour Time", systemImage: "calendar.badge.clock")
                }
                .onChange(of: show24hourtime) { value in
                  print("EventsView: Changing to show24hourtime = \(value)")
                }
              Toggle(isOn: $showPastEvents) {
                Label("Show Past Events", systemImage: "calendar")
              }
              .onChange(of: showPastEvents) { value in
                print("EventsView: Changing to showPastEvents = \(value)")
                viewModel.showPastEvents = value
                  toTop.val = true
              }
              .toggleStyle(.automatic)
            } label: {
              Image(systemName: "ellipsis")
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

            Button {
              showFilters.toggle()
            } label: {
              Image(
                systemName: filters.filters
                  .isEmpty
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
            }
          }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
      }
      .sheet(isPresented: $showFilters) {
        EventFilters(
          tagtypes: viewModel.tagtypes.filter {
            $0.category == "content" && $0.isBrowsable == true
          }, showFilters: $showFilters
        )
      }
      /*.onChange(of: viewModel.conference) { con in
        print("EventsView.onChange(of: conference) == \(con?.name ?? "not found")")
          filters.filters = []
      } */
    } else {
      VStack {
        EventScrollView(
          events:
            viewModel.events
            .filters(typeIds: filters.filters, bookmarks: bookmarks.map({$0.id}), tagTypes: viewModel.tagtypes)
            .search(text: searchText).eventDayGroup(
                showLocaltime: showLocaltime, conference: viewModel.conference
            ),
          dayTag: eventDay,
          showPastEvents: showPastEvents, includeNav: includeNav,
          // tappedScheduleTwice: $tappedScheduleTwice, schedule: $schedule,
          showLocaltime: $showLocaltime
        )
        .navigationTitle(navTitle)
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
          }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
      }
      .onChange(of: viewModel.conference) { con in
        print("EventsView.onChange(of: conference) == \(con?.name ?? "not found")")
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
    @EnvironmentObject var toTop: ToTop
    @EnvironmentObject var toCurrent: ToCurrent
    @EnvironmentObject var toBottom: ToBottom
    @EnvironmentObject var toNext: ToNext
    @State var viewShowing = false
    @Binding var showLocaltime: Bool
    @State var eventDayGroup: [(key: String, value: [Event])] = []

  var body: some View {
    ScrollViewReader { proxy in
      List(events, id: \.key) { weekday, dayEvents in
          if showPastEvents || dayEvents.contains(where: {Date() < $0.endTimestamp}) {
            EventData(
              weekday: weekday, events: dayEvents, showPastEvents: showPastEvents
            )
            .id(weekday)
        }
      }
      .listStyle(.plain)
      .onChange(of: dayTag) { changedValue in
        withAnimation {
          proxy.scrollTo(changedValue, anchor: .top)
        }
      }
      .onChange(of: toTop.val, perform: { tapTop in
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
      )
      .onChange(of: toBottom.val, perform: { tapBottom in
          guard tapBottom else { return }
          if tapBottom, let es = events.map({$0.value.sorted{$0.beginTimestamp < $1.beginTimestamp}}).last, let e = es.last {
              withAnimation {
                  proxy.scrollTo(e.id)
              }
              toBottom.val = false
          }
      })
      .onChange(of: toCurrent.val, perform: { tapCurrent in
          guard tapCurrent else { return }
          let curDate = Date()
          // print("events: \(events.key)")
          if tapCurrent, let es = events.flatMap({$0.value}).sorted(by: {$0.beginTimestamp < $1.beginTimestamp}).first(where: {curDate < $0.endTimestamp}) {
                  withAnimation {
                      proxy.scrollTo(es.id, anchor: .top)
                  }
              toCurrent.val = false
          }
      })
      .onChange(of: toNext.val, perform: { tapNext in
          guard tapNext else { return }
          let curDate = Date()
          // print("events: \(events.key)")
          if tapNext, let es = events.flatMap({$0.value}).sorted(by: {$0.beginTimestamp < $1.beginTimestamp}).first(where: {curDate < $0.beginTimestamp}) {
                  withAnimation {
                      proxy.scrollTo(es.id, anchor: .top)
                  }
              toNext.val = false
          }
      })
      .onAppear {
        viewShowing = true
      }
      .onDisappear {
        viewShowing = false
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
    Section(header: Text(weekday)) {
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
            }
          }
        }
      }
      .listStyle(.plain)
    }.headerProminence(.increased)
  }
}
