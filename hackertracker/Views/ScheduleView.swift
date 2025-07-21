//
//  ScheduleView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct ScheduleView: View {    
    var includeNav: Bool = true
    var navTitle: String = ""

    @Environment(\.colorScheme) var colorScheme


    init(tagId: Int? = nil, includeNav: Bool? = true, navTitle: String = "") {
        if let nav = includeNav {
            self.includeNav = nav
        }
        self.navTitle = navTitle
    }
    
    init(tagIds: [Int] = [], includeNav: Bool? = true, navTitle: String = "") {
        if let nav = includeNav {
            self.includeNav = nav
        }
        self.navTitle = navTitle
    }

    var body: some View {
        EventsView(includeNav: includeNav, navTitle: navTitle)
            .analyticsScreen(name: "ScheduleView")
    }
}
