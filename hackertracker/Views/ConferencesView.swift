//
//  ConferencesView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/13/22.
//

import CoreData
import FirebaseStorage
import SwiftUI

struct ConferencesView: View {
    // var conferences: [Conference]
    @EnvironmentObject var selected: SelectedConference
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ConferencesViewModel.self) private var consViewModel
    @EnvironmentObject var filters: Filters
    @Environment(\.presentationMode) var presentationMode
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage(AppStorageKeys.conferenceCode) var conferenceCode: String = "INIT"
    @AppStorage(AppStorageKeys.showHidden) var showHidden: Bool = false
    @AppStorage(AppStorageKeys.showLocaltime) var showLocaltime: Bool = false
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>

    // Polish parity with the other top-level lists.
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var jumpTarget: String?

    private var filteredConferences: [Conference] {
        guard !searchText.isEmpty else { return consViewModel.conferences }
        let needle = searchText.lowercased()
        return consViewModel.conferences.filter {
            $0.name.lowercased().contains(needle) || $0.code.lowercased().contains(needle)
        }
    }

    var body: some View {
        if consViewModel.conferences.count > 0 {
            VStack(spacing: 0) {
                InlineSearchBar(placeholder: "Search conferences", text: $searchText, isFocused: $searchFocused, visible: isSearching)
                ScrollView {
                    if filteredConferences.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .padding(.top, 60)
                    } else {
                        ScrollViewReader { proxy in
                            LazyVStack(spacing: 0) {
                                Color.clear.frame(height: 1).id("__top")
                                ForEach(filteredConferences, id: \.code) { conference in
                                    Button(action: {
                                        self.presentationMode.wrappedValue.dismiss()
                                        if conference.code == selected.code {
                                            Log.app.debug("already selected \(conference.name, privacy: .public)")
                                        } else {
                                            Log.app.info("selected \(conference.name, privacy: .public)")
                                            selected.code = conference.code
                                            conferenceCode = conference.code
                                            filters.filters.removeAll()
                                            viewModel.fetchData(code: conference.code)
                                            ClockService.apply(conference: conference, showLocaltime: showLocaltime)
                                        }
                                    }) {
                                        ConferenceRow(conference: conference, code: selected.code)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Color.clear.frame(height: 1).id("__bottom")
                            }
                            .onChange(of: jumpTarget) { _, target in
                                guard let target else { return }
                                withAnimation { proxy.scrollTo(target, anchor: .top) }
                                DispatchQueue.main.async { jumpTarget = nil }
                            }
                            // iPad: readable centered column for rows.
                            .iPadReadableContent()
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Spacer()
                    JumpMenuOverlay(target: $jumpTarget)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .navigationTitle("Select Conference")
            .themedNavTitle("Select Conference", themeManager)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    SearchToggleButton(isSearching: $isSearching, searchText: $searchText, isFocused: $searchFocused, searchLabel: "Search conferences")
                }
            }
            .analyticsScreen(name: "ConferencesView")
        } else {
            _04View(message: "Loading", show404: false).preferredColorScheme(.dark)
                .task {
                    consViewModel.fetchConferences(hidden: showHidden)
                }
        }
    }
}

struct ConferencesView_Previews: PreviewProvider {
    static var previews: some View {
        Text("ConferencesView")
        // ConferencesView()
    }
}
