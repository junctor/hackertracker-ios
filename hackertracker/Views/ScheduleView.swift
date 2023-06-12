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
        EventsView(events: viewModel.events)
            .onAppear {
                viewModel.fetchData(code: code)
                // $conferences.predicates = [.where("code", isEqualTo: conferenceCode)]
                // NSLog("Conference: \(conferences.first?.name ?? "No conference found for \(conferenceCode)?")")
                // NSLog("Conference \(conference.name) Events = \(self.viewModel.events.count)")
                if bookmarks.bookmarks.count < 1 {
                    bookmarks.bookmarks = Set(bookmarksResults.map { bookmark -> Int in
                        Int(bookmark.id)
                    })
                }
            }
            .environmentObject(bookmarks)
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduleView(code: "DEFCON30").environmentObject(oBookmarks())
        }
    }
}
