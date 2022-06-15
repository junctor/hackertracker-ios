//
//  SpeakerDetailView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI

struct SpeakerDetailView: View {
    @ObservedObject private var viewModel = SpeakerViewModel()
    var id: Int = 1
    var speaker: Speaker?
    var body: some View {
        VStack {
            Text(viewModel.speaker.name)
            Text(viewModel.speaker.title ?? "Hacker")
            Divider()
            Text(viewModel.speaker.description)
        }
        .onAppear {
            viewModel.fetchData(speakerId: String(id))
        }
    }
}

struct SpeakerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let preview_speaker = Speaker(docId: nil,
                                      id: 123,
                                      conferenceName: "DEFCON30",
                                      description: "Just as short test description",
                                      link: "https://google.com/",
                                      name: "Speaker Name",
                                      title: "Chief Hacking Officer",
                                      twitter: "defcon",
                                      events: [])
        SpeakerDetailView(id: 123, speaker: preview_speaker)
    }
}
