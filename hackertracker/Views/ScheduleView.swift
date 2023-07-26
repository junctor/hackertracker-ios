//
//  ScheduleView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct ScheduleView: View {
    @Binding var tappedScheduleTwice: Bool
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("launchScreen") var launchScreen: String = "Schedule"
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    var includeNav: Bool = true
    var navTitle: String = ""

    @Environment(\.colorScheme) var colorScheme

    @StateObject var filters: Filters

    init(tagId: Int? = nil, includeNav: Bool? = true, navTitle: String = "", tappedScheduleTwice: Binding<Bool>) {
        if let tagId = tagId {
            _filters = StateObject(wrappedValue: Filters(filters: Set([tagId])))
        } else {
            _filters = StateObject(wrappedValue: Filters(filters: Set<Int>()))
        }
        
        if let nav = includeNav {
            self.includeNav = nav
        }
        self.navTitle = navTitle
        self._tappedScheduleTwice = tappedScheduleTwice
    }
    
    init(tagIds: [Int] = [], includeNav: Bool? = true, navTitle: String = "", tappedScheduleTwice: Binding<Bool>) {
        if tagIds.count > 0 {
            _filters = StateObject(wrappedValue: Filters(filters: Set(tagIds)))
        } else {
            _filters = StateObject(wrappedValue: Filters(filters: Set<Int>()))
        }
        if let nav = includeNav {
            self.includeNav = nav
        }
        self.navTitle = navTitle
        self._tappedScheduleTwice = tappedScheduleTwice
    }

    var body: some View {
        EventsView(events: viewModel.events, conference: viewModel.conference, bookmarks: bookmarks.map { $0.id }, includeNav: includeNav, navTitle: navTitle, tappedScheduleTwice: $tappedScheduleTwice, filters: $filters.filters)
            .onAppear {
                print("ScheduleView: Current launchscreen is: \(launchScreen)")
            }
    }
}
