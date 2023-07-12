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

    @State private var eventDay = ""
    @State private var searchText = ""
    @State private var filters: Set<Int> = []
    @State private var showFilters = false
    var body: some View {
        NavigationStack {
            EventScrollView(events: events
                .filters(typeIds: filters, bookmarks: bookmarks)
                .search(text: searchText)
                .eventDayGroup(), bookmarks: bookmarks, dayTag: eventDay, showPastEvents: showPastEvents)
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
                                    dfu.update(tz: TimeZone(identifier: conference?.timezone ?? "America/Los_Angeles"))
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
                            ForEach(events.filters(typeIds: filters, bookmarks: bookmarks).eventDayGroup().sorted {
                                $0.key < $1.key
                            }, id: \.key) { day, _ in
                                Button(dfu.dayMonthDayOfWeekFormatter.string(from: day)) {
                                    eventDay = dfu.dayOfWeekFormatter.string(from: day) // day.formatted(.dateTime.weekday())
                                }
                            }

                        } label: {
                            Image(systemName: "chevron.up.chevron.down")
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
            EventFilters(tagtypes: viewModel.tagtypes.filter({$0.category == "content" && $0.isBrowsable == true}), showFilters: $showFilters, filters: $filters)
        }
        .onChange(of: viewModel.conference) { con in
            print("EventsView.onChange(of: conference) == \(con?.name ?? "not found")")
            self.filters = []
        }
    }
}

struct EventFilters: View {
    let tagtypes: [TagType]
    // let types: [Int: EventType]
    @Binding var showFilters: Bool
    @Binding var filters: Set<Int>
    
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                FilterRow(id: 1337, name: "Bookmarks", color: ThemeColors.blue, filters: $filters)

                ForEach(tagtypes.sorted { $0.sortOrder < $1.sortOrder }) { tagtype in
                    Section(header: Text(tagtype.label)) {
                        LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 10) {
                            ForEach(tagtype.tags.sorted { $0.sortOrder < $1.sortOrder }) { tag in
                                FilterRow(id: tag.id, name: tag.label, color: Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple), filters: $filters)
                            }
                        }
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
            .padding(5)
        }
    }
}

struct EventScrollView: View {
    let events: [Date: [Event]]
    let bookmarks: [Int32]
    let dayTag: String
    let showPastEvents: Bool
    let dfu = DateFormatterUtility.shared

    var body: some View {
        ScrollViewReader { proxy in
            List(events.sorted {
                $0.key < $1.key
            }, id: \.key) { weekday, events in
                if showPastEvents || weekday >= Date() {
                    EventData(weekday: weekday, events: events, bookmarks: bookmarks, showPastEvents: showPastEvents)
                        .id(dfu.dayOfWeekFormatter.string(from: weekday))
                }
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
    let bookmarks: [Int32]
    let showPastEvents: Bool
    let dfu = DateFormatterUtility.shared

    var body: some View {
        Section(header: Text(dfu.longMonthDayFormatter.string(from: weekday))) {
            ForEach(events.eventDateTimeGroup().sorted {
                $0.key < $1.key
            }, id: \.key) { time, timeEvents in
                if showPastEvents || time >= Date() {
                    Section {
                        ForEach(timeEvents.sorted {
                            $0.beginTimestamp < $1.beginTimestamp
                        }, id: \.id) { event in
                            if showPastEvents || event.beginTimestamp >= Date() {
                                NavigationLink(destination: EventDetailView(eventId: event.id)) {
                                    EventCell(event: event, bookmarks: bookmarks)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
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
        if !filters.contains(id) {
            VStack(alignment: .leading) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .padding(5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(5)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 2))
            .onTapGesture {
                if filters.contains(id) {
                    filters.remove(id)
                } else {
                    filters.insert(id)
                }
            }
        } else {
            VStack(alignment: .leading) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .padding(5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(5)
            .background(color)
            .cornerRadius(10)
            .onTapGesture {
                if filters.contains(id) {
                    filters.remove(id)
                } else {
                    filters.insert(id)
                }
            }
        }
    }
}
