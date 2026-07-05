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
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject var selected: SelectedConference
    @State private var searchText = ""

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var jumpTarget: String?
    /// iPad-only: selected org for the detail column.
    /// iPad-only: selected org id for the detail column.
    @State private var ipadSelectedOrgId: String?

    // iPad: GridItem(.adaptive) yields 2 columns on every iPhone width
    // and 4-6 columns on iPad portrait/landscape automatically.
    let gridItemLayout = IPadAdaptive.adaptiveGridColumns(minimum: 170, alignment: .top)

    private var filteredOrgs: [Organization] {
        viewModel.orgs.filter { $0.tag_ids.contains(tagId) }.search(text: searchText)
    }

    @ViewBuilder
    private var orgSidebar: some View {
        VStack(spacing: 0) {
            InlineSearchBar(placeholder: "Search \(title.lowercased())", text: $searchText, isFocused: $searchFocused, visible: isSearching)
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
                                OrgCell(org: org, theme: theme, tabSelection: $tabSelection)
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
                JumpMenuOverlay(target: $jumpTarget)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .navigationTitle(title)
        .themedNavTitle(title, themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                SearchToggleButton(isSearching: $isSearching, searchText: $searchText, isFocused: $searchFocused, searchLabel: "Search \(title.lowercased())")
            }
        }
        .analyticsScreen(name: "OrgsView")
    }

    var body: some View {
        if IPadAdaptive.isIPad {
            HStack(spacing: 0) {
                orgSidebar
                    .frame(width: IPadAdaptive.sidebarWidth)
                Divider()
                Group {
                    if let id = ipadSelectedOrgId,
                       let org = viewModel.orgsById[id] {
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

struct OrgCell: View {
    let org: Organization
    let theme: Theme
    @Binding var tabSelection: Int
    @Environment(\.iPadOrgSelection) private var iPadOrgSelection

    var body: some View {
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

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        if let l = org.logo, let lurl = l.url, let logo_url = URL(string: lurl) {
            VStack {
                Text(org.name)
                    .font(themeManager.captionFont)
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
            .background(colorMode ? theme.carousel(): themeManager.cardSurface)
            .cornerRadius(15)

        } else {
            Text(org.name)
                .foregroundColor(colorMode ? .white : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
                .background(colorMode ? theme.carousel(): themeManager.cardSurface)
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
