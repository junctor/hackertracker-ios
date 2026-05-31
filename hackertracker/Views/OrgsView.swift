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

    let gridItemLayout = [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)]

    private var filteredOrgs: [Organization] {
        viewModel.orgs.filter { $0.tag_ids.contains(tagId) }.search(text: searchText)
    }

    var body: some View {
        // Phase 5a: pull-to-refresh + empty-state UX.
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
                LazyVGrid(columns: gridItemLayout, spacing: 20) {
                    ForEach(filteredOrgs, id: \.id) { org in
                        NavigationLink(destination: OrgView(org: org, tabSelection: $tabSelection)) {
                            orgRow(org: org, theme: theme)
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
        .navigationTitle(title)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .analyticsScreen(name: "OrgsView")
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
