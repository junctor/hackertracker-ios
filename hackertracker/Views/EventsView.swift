//
//  EventsView.swift
//
//  Created by Caleb Kinney on 3/27/23.
//

import SwiftUI

struct EventsView: View {
  let events: [Event]
  let conference: Conference?
  let bookmarks: [Int32]
  @AppStorage("showLocaltime") var showLocaltime: Bool = false
  @AppStorage("showPastEvents") var showPastEvents: Bool = true
  @EnvironmentObject var viewModel: InfoViewModel
  let dfu = DateFormatterUtility.shared
  var includeNav: Bool = true
  var navTitle: String = ""
  @Binding var tappedScheduleTwice: Bool
  @Binding var schedule: UUID

  @State private var eventDay = ""
  @State private var searchText = ""
  @Binding var filters: Set<Int>
  @State private var showFilters = false

  var body: some View {
    if includeNav {
      NavigationView {
        EventScrollView(
          events:
            events
            .filters(typeIds: filters, bookmarks: bookmarks, tagTypes: viewModel.tagtypes)
            .search(text: searchText).eventDayGroup(showLocaltime: showLocaltime, conference: conference), conference: conference, bookmarks: bookmarks,
          dayTag: eventDay,
          showPastEvents: showPastEvents, includeNav: includeNav,
          tappedScheduleTwice: $tappedScheduleTwice, schedule: $schedule,
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
                viewModel.showLocaltime = value
                if showLocaltime {
                  dfu.update(tz: TimeZone.current)
                } else {
                  dfu.update(
                    tz: TimeZone(identifier: conference?.timezone ?? "America/Los_Angeles"))
                }
              }
              Toggle(isOn: $showPastEvents) {
                Label("Show Past Events", systemImage: "calendar")
              }
              .onChange(of: showPastEvents) { value in
                print("EventsView: Changing to showPastEvents = \(value)")
                viewModel.showPastEvents = value
              }
              .toggleStyle(.automatic)
            } label: {
              Image(systemName: "ellipsis")
            }
          }
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
              Button {
                self.tappedScheduleTwice = true
              } label: {
                HStack {
                  Text("Top")
                  Image(systemName: "chevron.up")
                }
              }
              ForEach(
                events.filters(typeIds: filters, bookmarks: bookmarks, tagTypes: viewModel.tagtypes).eventDayGroup(showLocaltime: showLocaltime, conference: conference)
, id: \.key
              ) { day, _ in
                Button(day) {
                  eventDay = day
                }
              }

            } label: {
              Image(systemName: "chevron.up.chevron.down")
            }

            Button {
              showFilters.toggle()
            } label: {
              Image(
                systemName: filters
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
          }, showFilters: $showFilters, filters: $filters
        )
      }
      .onChange(of: viewModel.conference) { con in
        print("EventsView.onChange(of: conference) == \(con?.name ?? "not found")")
        self.filters = []
      }
    } else {
      VStack {
        EventScrollView(
          events:
            events
            .filters(typeIds: filters, bookmarks: bookmarks, tagTypes: viewModel.tagtypes)
            .search(text: searchText).eventDayGroup(showLocaltime: showLocaltime, conference: conference), conference: conference, bookmarks: bookmarks,
          dayTag: eventDay,
          showPastEvents: showPastEvents, includeNav: includeNav,
          tappedScheduleTwice: $tappedScheduleTwice, schedule: $schedule,
          showLocaltime: $showLocaltime
        )
        .navigationTitle(navTitle)
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
              ForEach(
                events.filters(typeIds: filters, bookmarks: bookmarks, tagTypes: viewModel.tagtypes)
                    .eventDayGroup(showLocaltime: showLocaltime, conference: conference), id: \.key
              ) { day, _ in
                Button(day) {
                  eventDay = day
                }
              }

            } label: {
              Image(systemName: "chevron.up.chevron.down")
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
  let conference: Conference?
  let bookmarks: [Int32]
  let dayTag: String
  let showPastEvents: Bool
  let includeNav: Bool
  let dfu = DateFormatterUtility.shared
  @Binding var tappedScheduleTwice: Bool
  @EnvironmentObject var viewModel: InfoViewModel
  @State var viewShowing = false
  @Binding var schedule: UUID
  @Binding var showLocaltime: Bool
  @State var eventDayGroup: [(key: String, value: [Event])] = []

  var body: some View {
    ScrollViewReader { proxy in
      List(events, id: \.key) { weekday, dayEvents in
        // if showPastEvents || weekday >= Date() {
        EventData(
          weekday: weekday, events: dayEvents, bookmarks: bookmarks, showPastEvents: showPastEvents
        )
        .id(weekday)
        // }
      }
      .listStyle(.plain)
      .onChange(of: dayTag) { changedValue in
        withAnimation {
          proxy.scrollTo(changedValue, anchor: .top)
        }
      }
      .onChange(
        of: tappedScheduleTwice,
        perform: { tappedTwice in
          guard tappedTwice else { return }
          let es = eventDayGroup
          if viewShowing, includeNav {
            if let f = es.first, let e = f.value.first {
              let id: String = dfu.dayOfWeekFormatter.string(from: e.beginTimestamp)
              withAnimation {
                proxy.scrollTo(id, anchor: .top)
              }
              // schedule = UUID()
            }
          } else {
            print("EventScrollView: reset UUID here!")
            schedule = UUID()
          }
          self.tappedScheduleTwice = false
        }
      )
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
  let bookmarks: [Int32]
  let showPastEvents: Bool

  var body: some View {
    Section(header: Text(weekday)) {
      Section {
        ForEach(
          events.sorted {
            $0.beginTimestamp < $1.beginTimestamp
          }, id: \.id
        ) { event in
          if showPastEvents || event.beginTimestamp >= Date() {
            NavigationLink(destination: EventDetailView(eventId: event.id)) {
              EventCell(event: event, bookmarks: bookmarks, showDay: false)
            }
          }
        }
      }
      .listStyle(.plain)
    }.headerProminence(.increased)
  }
}
