//
//  SpeakersView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI

struct SpeakersView: View {
    var speakers: [Speaker]
    @State private var searchText = ""

    func speakerGroup() -> [String.Element: [Speaker]] {
        return Dictionary(grouping: speakers.search(text: searchText), by: { $0.name.lowercased().first ?? "-" })
    }

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { _ in
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        ForEach(self.speakerGroup().sorted {
                            $0.key < $1.key
                        }, id: \.key) { char, speakers in
                            SpeakerData(char: char, speakers: speakers)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
        }
    }
}

struct SpeakerData: View {
    let char: String.Element
    let speakers: [Speaker]
    @EnvironmentObject var theme: Theme

    var body: some View {
        Section(header: Text(String(char.uppercased()))
            .font(.subheadline)
            .padding(1)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
        ) {
            ForEach(speakers, id: \.name) { speaker in
                NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                    SpeakerRow(speaker: speaker, themeColor: theme.carousel())
                }
            }
        }
    }
}

struct SpeakersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpeakersView(speakers: []).preferredColorScheme(.dark)
        }
    }
}
