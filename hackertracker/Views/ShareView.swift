//
//  ShareView.swift
//
//  Created by Caleb Kinney on 5/17/23.
//

import SwiftUI

struct ShareView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    let event: Event
    let title: Bool

    init(event: Event, title: Bool = true) {
        self.event = event
        self.title = title
    }

    func shareText() -> String {
        return """
        \(viewModel.conference?.name ?? "HT"): Attending \(event.title) on \(event.beginTimestamp.formatted(date: .abbreviated, time: .shortened)) in \(event.location.name)
        #hackertracker
        """
    }

    var body: some View {
        VStack {
            ShareLink(title ? "Share" : "", item: shareText())
        }
    }
}
