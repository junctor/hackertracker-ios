//
//  ScheduleView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var selected: SelectedConference
    @ObservedObject var viewModel = ScheduleViewModel()
    @Environment(\.managedObjectContext) private var viewContext
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
        EventsView(events: viewModel.events, conference: viewModel.conference, bookmarks: bookmarks.map{ $0.id })
            .onAppear {
                print("ScheduleView: Getting Schedule for \(selected.code)")
                viewModel.fetchData(code: selected.code)
                    // $conferences.predicates = [.where("code", isEqualTo: conferenceCode)]
                    // NSLog("Conference: \(conferences.first?.name ?? "No conference found for \(conferenceCode)?")")
                    // NSLog("Conference \(conference.name) Events = \(self.viewModel.events.count)")
                    /* if bookmarks.bookmarks.count < 1 {
                     bookmarks.bookmarks = Set(bookmarksResults.map { bookmark -> Int in
                     Int(bookmark.id)
                     })
                    } */
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
