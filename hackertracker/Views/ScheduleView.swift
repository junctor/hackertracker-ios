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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmarks.id, ascending: true)],
        animation: .default)
    private var bookmarksResults: FetchedResults<Bookmarks>
    @State var bookmarks: [Int] = []
    
    var body: some View {
        List (viewModel.events, id: \.id) { event in
            EventRow(event: event, bookmarks: bookmarks)
        }
        .onAppear() {
            self.viewModel.fetchData()
            bookmarks = bookmarksResults.map{ bookmark -> Int in
                return Int(bookmark.id)
            }
        }
        .listStyle(.plain)
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}
