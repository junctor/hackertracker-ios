//
//  ScheduleView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct ScheduleView: View {
    var code: String
    // @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @StateObject var viewModel = ScheduleViewModel()
    // viewModel.fetchData(conferenceCode: conference.code)
    
    @State var activeTab = ""
    @Environment(\.colorScheme) var colorScheme

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmarks.id, ascending: true)],
        animation: .default
    )
    private var bookmarksResults: FetchedResults<Bookmarks>
    @EnvironmentObject var bookmarks: oBookmarks

    var body: some View {
        ScrollViewReader { scroll in
            // if let events = conference.events {
                HStack {
                    ForEach(viewModel.eventTabs(), id: \.self) { tab in
                        Button(tab) {
                            withAnimation {
                                activeTab = tab
                                scroll.scrollTo(toTabId(date: tab), anchor: .top)
                            }
                        }.padding(10)
                            .background(activeTab == tab ? ThemeColors.pink : nil)
                            .foregroundColor(colorScheme == .dark ? Color.white: ThemeColors.gray)
                            .clipShape(Capsule())
                        
                    }.onAppear {
                        activeTab = viewModel.eventTabs().first ?? ""
                    }
                }.padding(.top, 5)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: nil, pinnedViews: .sectionHeaders) {
                        ForEach(viewModel.eventGroup().sorted {
                            $0.key < $1.key
                        }, id: \.key) { weekday, events in
                            EventData(weekday: weekday, events: events).id(weekday)
                        }
                    }
                }
            // }
        }
        .onAppear {
            viewModel.fetchData(code: code)
            // $conferences.predicates = [.where("code", isEqualTo: conferenceCode)]
            // NSLog("Conference: \(conferences.first?.name ?? "No conference found for \(conferenceCode)?")")
            // NSLog("Conference \(conference.name) Events = \(self.viewModel.events.count)")
            if bookmarks.bookmarks.count < 1 {
                bookmarks.bookmarks = bookmarksResults.map { bookmark -> Int in
                    Int(bookmark.id)
                }
            }
        }
    }
}

struct EventData: View {
    let weekday: String
    let events: [Event]

    var body: some View {
        Section(header: Text(weekday).bold().frame(maxWidth: .infinity, alignment: .center).padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.systemBackground))) {
                ForEach(events, id: \.title) { event in
                    NavigationLink(destination: EventDetailView(id: event.id)) {
                        EventRow(event: event)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduleView(code: "DEFCON30").environmentObject(oBookmarks())
        }
    }
}
