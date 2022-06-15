//
//  SpeakersView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI

struct SpeakersView: View {
    @ObservedObject private var viewModel = SpeakersViewModel()
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"

    var body: some View {
        List(viewModel.speakers, id: \.id) { speaker in
            NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                SpeakerRow(speaker: speaker)
            }
        }
        .onAppear {
            self.viewModel.fetchData()
        }
        .listStyle(.plain)
    }
}

struct SpeakersView_Previews: PreviewProvider {
    static var previews: some View {
        SpeakersView()
    }
}
