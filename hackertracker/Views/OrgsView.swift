//
//  OrgsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import FirebaseFirestore
import SwiftUI
import Kingfisher

struct OrgsView: View {
    var title: String
    var tagId: Int
    @Binding var tabSelection: Int
    @EnvironmentObject var theme: Theme
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var selected: SelectedConference
    @State private var searchText = ""

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var jumpTarget: String?
    /// iPad-only: selected org for the detail column.
    /// iPad-only: selected org id for the detail column.
    @State private var ipadSelectedOrgId: String?
    /// iPad split-view: row taps update detail column instead of pushing.
    @Environment(\.iPadOrgSelection) private var iPadOrgSelection

    // iPad: GridItem(.adaptive) yields 2 columns on every iPhone width
    // and 4-6 columns on iPad portrait/landscape automatically.
    let gridItemLayout = IPadAdaptive.adaptiveGridColumns(minimum: 170, alignment: .top)

    private var filteredOrgs: [Organization] {
        viewModel.orgs.filter { $0.tag_ids.contains(tagId) }.search(text: searchText)
    }

    @ViewBuilder private var inlineSearchBar: some View {
        if isSearching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search \(title.lowercased())", text: $searchText)
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
        .accessibilityLabel(isSearching ? "Close search" : "Search \(title.lowercased())")
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

    @ViewBuilder
    private var orgSidebar: some View {
        VStack(spacing: 0) {
            inlineSearchBar
            ScrollView {
                if filteredOrgs.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "No \(title)",
                            systemImage: "building.2",
                            description: Text("Listings will appear here once they're published.")
                        )
                        .padding(.top, 60)
                    } else {
                        ContentUnavailableView.search(text: searchText)
                            .padding(.top, 60)
                    }
                } else {
                    ScrollViewReader { proxy in
                        Color.clear.frame(height: 1).id("__top")
                        LazyVGrid(columns: gridItemLayout, spacing: 20) {
                            ForEach(filteredOrgs, id: \.id) { org in
                                if let sel = iPadOrgSelection {
                                    Button {
                                        sel.wrappedValue = org.id
                                    } label: {
                                        orgRow(org: org, theme: theme)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink(destination: OrgView(org: org, tabSelection: $tabSelection)) {
                                        orgRow(org: org, theme: theme)
                                    }
                                }
                            }
                        }
                        Color.clear.frame(height: 1).id("__bottom")
                            .onChange(of: jumpTarget) { _, target in
                                guard let target else { return }
                                withAnimation { proxy.scrollTo(target, anchor: .top) }
                                DispatchQueue.main.async { jumpTarget = nil }
                            }
                    }
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                searchToggleButton
            }
        }
        .analyticsScreen(name: "OrgsView")
    }

    var body: some View {
        if IPadAdaptive.isIPad {
            HStack(spacing: 0) {
                NavigationStack {
                    orgSidebar
                }
                .frame(width: 420)
                Divider()
                NavigationStack {
                    if let id = ipadSelectedOrgId,
                       let org = viewModel.orgs.first(where: { $0.id == id }) {
                        OrgView(org: org, tabSelection: $tabSelection)
                            .id(id)
                    } else {
                        ContentUnavailableView(
                            "Select an Organization",
                            systemImage: "building.2",
                            description: Text("Tap an item in the list to view details.")
                        )
                    }
                }
            }
            .environment(\.iPadOrgSelection, $ipadSelectedOrgId)
        } else {
            orgSidebar
        }
    }
}

struct orgSearchRow: View {
    let org: Organization
    let themeColor: Color
    
    var body: some View {
        HStack {
            Rectangle().fill(themeColor)
                .frame(width: 6)
                .frame(maxHeight: .infinity)
            Text(org.name)
        }
    }
}

struct orgRow: View {
    let org: Organization
    var theme: Theme
    @AppStorage("colorMode") var colorMode: Bool = false

    var body: some View {
        if let l = org.logo, let lurl = l.url, let logo_url = URL(string: lurl) {
            VStack {
                Text(org.name)
                    .font(.caption)
                    .foregroundColor(colorMode ? .white : .primary)
                KFImage(logo_url)
                    .htDownsampled(side: 200)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(15)
            }
            .padding(5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorMode ? theme.carousel(): Color(.systemGray6))
            .cornerRadius(15)

        } else {
            Text(org.name)
                .foregroundColor(colorMode ? .white : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
                .background(colorMode ? theme.carousel(): Color(.systemGray6))
                .cornerRadius(15)
        }
    }
}

struct OrgsView_Previews: PreviewProvider {
    static var previews: some View {
        Text("OrgsView")
        // OrgsView(title: "Vendors", tagId: 45695)
    }
}
