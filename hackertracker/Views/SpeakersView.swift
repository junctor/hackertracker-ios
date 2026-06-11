//
//  SpeakersView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI

struct SpeakersView: View {
    var speakers: [Speaker]
    @Environment(InfoViewModel.self) private var viewModel
    @State private var searchText = ""

    private var grouped: [(key: String.Element, value: [Speaker])] {
        Dictionary(grouping: speakers.search(text: searchText),
                   by: { $0.name.lowercased().first ?? "-" })
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        // Phase 5a: pull-to-refresh + empty-state UX.
        ScrollView {
            if grouped.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Speakers",
                        systemImage: "person.2",
                        description: Text("Conference presenters will appear here once they're announced.")
                    )
                    .padding(.top, 60)
                } else {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 60)
                }
            } else {
                ScrollViewReader { _ in
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        ForEach(grouped, id: \.key) { char, speakers in
                            SpeakerData(char: char, speakers: speakers)
                        }
                    }
                }
            }
        }
        .refreshable {
            if let code = viewModel.conference?.code {
                viewModel.fetchData(code: code)
            }
        }
        .searchable(text: $searchText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .analyticsScreen(name: "SpeakersView")
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
            // Phase 6 polish: match the toolbar's frosted material.
            .background(.ultraThinMaterial)
        ) {
            ForEach(speakers, id: \.id) { speaker in
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
