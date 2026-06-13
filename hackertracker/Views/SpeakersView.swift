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

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var scrollToGroup: String.Element?
    @State private var lastJumpedGroup: String.Element?
    /// iPad-only: identifies the speaker currently shown in the detail column.
    @State private var ipadSelectedSpeakerId: Int?

    private var grouped: [(key: String.Element, value: [Speaker])] {
        Dictionary(grouping: speakers.search(text: searchText),
                   by: { $0.name.lowercased().first ?? "-" })
            .sorted { $0.key < $1.key }
    }

    @ViewBuilder private var inlineSearchBar: some View {
        if isSearching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search speakers", text: $searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search text")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder private var searchToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearching.toggle()
            }
            if isSearching {
                searchFocused = true
            } else {
                searchText = ""
            }
        } label: {
            Image(systemName: isSearching ? "xmark.circle" : "magnifyingglass")
        }
        .accessibilityLabel(isSearching ? "Close search" : "Search speakers")
    }

    @ViewBuilder private var jumpToGroupMenu: some View {
        Menu {
            ForEach(grouped, id: \.key) { char, _ in
                Button(String(char).uppercased()) {
                    scrollToGroup = char
                    lastJumpedGroup = char
                }
            }
            Divider()
            Button {
                if let first = grouped.first?.key {
                    scrollToGroup = first
                    lastJumpedGroup = first
                }
            } label: { Label("Top", systemImage: "arrow.up") }
            Button {
                if let last = lastJumpedGroup,
                   let idx = grouped.firstIndex(where: { $0.key == last }),
                   idx + 1 < grouped.count {
                    let next = grouped[idx + 1].key
                    scrollToGroup = next
                    lastJumpedGroup = next
                } else if let fallback = grouped.dropFirst().first?.key ?? grouped.first?.key {
                    scrollToGroup = fallback
                    lastJumpedGroup = fallback
                }
            } label: { Label("Next Group", systemImage: "arrow.turn.right.down") }
            Button {
                if let last = grouped.last?.key {
                    scrollToGroup = last
                    lastJumpedGroup = last
                }
            } label: { Label("Bottom", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }

    @ViewBuilder
    private var speakerSidebar: some View {
        VStack(spacing: 0) {
            inlineSearchBar
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
                    ScrollViewReader { proxy in
                        LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                            ForEach(grouped, id: \.key) { char, speakers in
                                SpeakerData(char: char, speakers: speakers)
                                    .id(char)
                            }
                        }
                        .onChange(of: scrollToGroup) { _, target in
                            guard let target else { return }
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                            DispatchQueue.main.async { scrollToGroup = nil }
                        }
                    }
                    .iPadReadableContent()
                }
            }
            .refreshable {
                if let code = viewModel.conference?.code {
                    viewModel.fetchData(code: code)
                }
            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                Spacer()
                jumpToGroupMenu
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(.regularMaterial, in: Circle())
                    .accessibilityLabel("Jump to group")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .navigationTitle("Speakers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                searchToggleButton
            }
        }
        .analyticsScreen(name: "SpeakersView")
    }

    var body: some View {
        if IPadAdaptive.isIPad {
            HStack(spacing: 0) {
                speakerSidebar
                    .frame(width: 380)
                Divider()
                Group {
                    if let id = ipadSelectedSpeakerId {
                        SpeakerDetailView(id: id)
                            .id(id)
                    } else {
                        ContentUnavailableView(
                            "Select a Speaker",
                            systemImage: "person.2",
                            description: Text("Tap a speaker in the list to view their details.")
                        )
                    }
                }
            }
            .environment(\.iPadSpeakerSelection, $ipadSelectedSpeakerId)
        } else {
            speakerSidebar
        }
    }
}

struct SpeakerData: View {
    let char: String.Element
    let speakers: [Speaker]
    @EnvironmentObject var theme: Theme
    /// iPad split-view: row taps update detail column instead of pushing.
    @Environment(\.iPadSpeakerSelection) private var iPadSpeakerSelection

    var body: some View {
        Section(header: Text(String(char.uppercased()))
            .font(.subheadline)
            .padding(1)
            .frame(maxWidth: .infinity)
            // Phase 6 polish: match the toolbar's frosted material.
            .background(.ultraThinMaterial)
        ) {
            ForEach(speakers, id: \.id) { speaker in
                if let sel = iPadSpeakerSelection {
                    Button {
                        sel.wrappedValue = speaker.id
                    } label: {
                        SpeakerRow(speaker: speaker, themeColor: theme.carousel())
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                        SpeakerRow(speaker: speaker, themeColor: theme.carousel())
                    }
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
