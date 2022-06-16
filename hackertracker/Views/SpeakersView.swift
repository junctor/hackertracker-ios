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
        VStack {
            ScrollView {
                ScrollViewReader { _ in
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        ForEach(viewModel.speakerGroup().sorted {
                            $0.key < $1.key
                        }, id: \.key) { char, speakers in
                            SpeakerData(char: char, speakers: speakers)
                        }
                    }
                }
            }
        }.onAppear {
            self.viewModel.fetchData()
        }
    }
}

struct SpeakerData: View {
    let char: String.Element
    let speakers: [Speaker]

    var body: some View {
        Section(header: Text(String(char)).padding()
            .frame(maxWidth: .infinity)
            .border(Color.white, width: 3)
            .background(Color.black)) {
                ForEach(speakers, id: \.name) { speaker in
                    NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                        SpeakerRow(speaker: speaker)
                    }
                }
            }
    }
}

struct SpeakersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpeakersView().preferredColorScheme(.dark)
        }
    }
}
