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

    @Environment(\.colorScheme) var colorScheme
    
    @StateObject var filters: Filters
    
    init(tagIds: [Int] = []) {
        _filters = StateObject(wrappedValue: Filters(filters: Set(tagIds)))
    }
    
    var body: some View {
        EventsView(events: viewModel.events, conference: viewModel.conference, bookmarks: bookmarks.map { $0.id }, filters: $filters.filters)
            .onAppear {
                print("ScheduleView: Current launchscreen is: \(launchScreen)")
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
