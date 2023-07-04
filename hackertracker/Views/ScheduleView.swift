//
//  ScheduleView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("launchScreen") var launchScreen: String = "Schedule"
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>

    // viewModel.fetchData(conferenceCode: conference.code)

    @Environment(\.colorScheme) var colorScheme

    /* @FetchRequest(
         sortDescriptors: [NSSortDescriptor(keyPath: \Bookmarks.id, ascending: true)],
         animation: .default
     )
     private var bookmarksResults: FetchedResults<Bookmarks>
     @EnvironmentObject var bookmarks: oBookmarks */

    var body: some View {
        EventsView(events: viewModel.events, conference: viewModel.conference, bookmarks: bookmarks.map { $0.id })
            .onAppear {
                print("ScheduleView: Current launchscreen is: \(launchScreen)")
                // launchScreen = "Schedule"
            }
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduleView()
        }
    }
}
