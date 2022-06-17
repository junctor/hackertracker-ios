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

    @EnvironmentObject var bookmarks: oBookmarks

    var body: some View {
        List(viewModel.events, id: \.id) { event in
            NavigationLink(destination: EventDetailView(id: event.id)) {
                EventRow(event: event)
            }
        }
        .onAppear {
            self.viewModel.fetchData()
        }
        .listStyle(.plain)
        .navigationViewStyle(.stack)
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}
