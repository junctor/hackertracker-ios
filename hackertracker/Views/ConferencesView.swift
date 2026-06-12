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
    @EnvironmentObject var theme: Theme
    @Environment(ConferencesViewModel.self) private var consViewModel
    @EnvironmentObject var filters: Filters
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("conferenceCode") var conferenceCode: String = "INIT"
    @AppStorage("showHidden") var showHidden: Bool = false
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
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

    @ViewBuilder private var inlineSearchBar: some View {
        if isSearching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search conferences", text: $searchText)
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
        .accessibilityLabel(isSearching ? "Close search" : "Search conferences")
    }

    @ViewBuilder private var jumpMenu: some View {
        Menu {
            Button {
                jumpTarget = "__top"
            } label: { Label("Top", systemImage: "arrow.up") }
            Button {
                jumpTarget = "__bottom"
            } label: { Label("Bottom", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }

    var body: some View {
        if consViewModel.conferences.count > 0 {
            VStack(spacing: 0) {
                inlineSearchBar
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
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Spacer()
                    jumpMenu
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .frame(width: 48, height: 48)
                        .background(.regularMaterial, in: Circle())
                        .accessibilityLabel("Jump")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .navigationTitle("Select Conference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    searchToggleButton
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
