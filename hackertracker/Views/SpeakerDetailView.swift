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
        ScrollView {
            VStack(alignment: .leading) {
                Text(viewModel.speaker.name).font(.largeTitle)
                Text(viewModel.speaker.title ?? "Hacker")
                Divider()
                Text(viewModel.speaker.description).padding(.top).padding()
                Text("Events").font(.headline).padding(.top)
                VStack(alignment: .leading) {
                    ForEach(speaker?.events ?? []) { event in
                        SpeakerEventsView(event: event, bookmarks: [])
                    }
                }
                .rectangleBackground()
            }
            Spacer()
        }
        .onAppear {
            viewModel.fetchData(speakerId: String(id))
        }
    }
}

struct SpeakerEventsView: View {
    var event: SpeakerEvent
    @State var bookmarks: [Int]

    var body: some View {
        HStack {
            Rectangle().fill(Color.yellow).frame(width: 10, height: .infinity)
            VStack(alignment: .leading) {
                Text(event.title ?? "").fontWeight(.bold)
            }
        }
    }
}

struct SpeakerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let preview_speaker = Speaker(docId: nil,
                                      id: 123,
                                      conferenceName: "DEFCON30",
                                      description: "Just as short test description. ",
                                      link: "https://google.com/",
                                      name: "Speaker Name",
                                      title: "Chief Hacking Officer",
                                      twitter: "defcon",
                                      events: [SpeakerEvent(id: 1337, title: "Speaker event1 title"), SpeakerEvent(id: 1338, title: "Speaker event2 title")])
        SpeakerDetailView(id: 123, speaker: preview_speaker).preferredColorScheme(.dark)
    }
}
