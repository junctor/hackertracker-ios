//
//  EventsView.swift
//
//  Created by Caleb Kinney on 3/27/23.
//

import SwiftUI

struct EventsView: View {
    let events: [Event]
    let conference: Conference?
    @State private var eventDay = ""
    @State private var searchText = ""
    @State private var filters: Set<Int> = []
    @State private var showFilters = false
    var body: some View {
        NavigationStack {
            EventScrollView(events: events
                .filters(typeIds: filters)
                .search(text: searchText)
                .eventDayGroup(), dayTag: eventDay)
            .navigationTitle(conference?.name ?? "Schedule")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Menu {
                            ForEach(events.filters(typeIds: filters).eventDayGroup().sorted {
                                $0.key < $1.key
                            }, id: \.key) { day, _ in
                                Button(day.formatted(.dateTime.month().day().weekday())) {
                                    eventDay = day.formatted(.dateTime.weekday())
                                }
                            }

                        } label: {
                            Image(systemName: "calendar")
                        }

                        Button {
                            showFilters.toggle()
                        } label: {
                            Image(systemName: filters
                                .isEmpty
                                ? "line.3.horizontal.decrease.circle"
                                : "line.3.horizontal.decrease.circle.fill")
                        }
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        }
        .sheet(isPresented: $showFilters) {
            EventFilters(types: events.types(), showFilters: $showFilters, filters: $filters)
        }
    }
}

struct EventFilters: View {
    let types: [Int: EventType]
    @Binding var showFilters: Bool
    @Binding var filters: Set<Int>

    var body: some View {
        NavigationStack {
            List {
                FilterRow(id: 1337, name: "Bookmarks", color: .primary, filters: $filters)

                Section(header: Text("Event Category")) {
                    ForEach(types.sorted {
                        $0.value.name < $1.value.name
                    }, id: \.key) { id, type in
                        FilterRow(id: id, name: type.name, color: type.swiftuiColor, filters: $filters)
                    }
                }.headerProminence(.increased)
            }
            .listStyle(.plain)
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        filters.removeAll()
                    }
                    Button("Close") {
                        showFilters = false
                    }
                }
            }
        }
    }
}

struct EventScrollView: View {
    let events: [Date: [Event]]
    let dayTag: String

    var body: some View {
        ScrollViewReader { proxy in
            List(events.sorted {
                $0.key < $1.key
            }, id: \.key) { weekday, events in
                EventData(weekday: weekday, events: events)
                    .id(weekday.formatted(.dateTime.weekday()))
            }
            .listStyle(.plain)
            .onChange(of: dayTag) { changedValue in
                proxy.scrollTo(changedValue, anchor: .top)
            }
        }
    }
}

struct EventData: View {
    let weekday: Date
    let events: [Event]

    var body: some View {
        Section(header: Text(weekday.formatted(.dateTime.month(.wide).day()))) {
            ForEach(events.eventDateTimeGroup().sorted {
                $0.key < $1.key
            }, id: \.key) { time, timeEvents in
                Section(header: Text(time.formatted(.dateTime.hour().minute()))) {
                    ForEach(timeEvents.sorted {
                        $0.beginTimestamp < $1.beginTimestamp
                    }, id: \.id) { event in
                        NavigationLink(destination: EventDetailView2(event: event)) {
                            EventCell(event: event)
                        }
                    }
                }
            }
        }
        .headerProminence(.increased)
    }
}

struct FilterRow: View {
    let id: Int
    let name: String
    let color: Color
    @Binding var filters: Set<Int>

    var body: some View {
        HStack {
            if !filters.contains(id) {
                Circle()
                    .strokeBorder(color, lineWidth: 5)
                    .frame(width: 25, height: 25).padding()
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 25, height: 25)
                    .padding()
            }
            Text(name)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if filters.contains(id) {
                filters.remove(id)
            } else {
                filters.insert(id)
            }
        }
    }
}
