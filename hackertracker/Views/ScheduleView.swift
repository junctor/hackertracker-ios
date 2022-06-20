//
//  ScheduleView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct ScheduleView: View {
    @ObservedObject private var viewModel = ScheduleViewModel()
    @AppStorage("conferenceName") var conferenceName: String = "DEF CON 30"
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @State var activeTab = ""
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var bookmarks: oBookmarks

    var body: some View {
        ScrollViewReader { scroll in
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
        }.onAppear {
            self.viewModel.fetchData()
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
            ScheduleView().environmentObject(oBookmarks())
        }
    }
}
