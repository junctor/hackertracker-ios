//
//  OrgsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import FirebaseFirestoreSwift
import SwiftUI

struct OrgsView: View {
    var title: String
    var tagId: Int
    var theme = Theme()
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var selected: SelectedConference
    @State private var searchText = ""

    let gridItemLayout = [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 20) {
                ForEach(self.viewModel.orgs.filter { $0.tag_ids.contains(tagId) }.search(text: searchText), id: \.id) { org in
                    NavigationLink(destination: DocumentView(title_text: org.name, body_text: org.description)) {
                        orgRow(org: org, theme: theme)
                    }
                }
            }
        }
        .navigationTitle(title)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
    }
}

struct orgRow: View {
    let org: Organization
    var theme: Theme

    var body: some View {
        if let l = org.logo, let lurl = l.url, let logo_url = URL(string: lurl) {
            VStack {
                Text(org.name)
                    .font(.caption)
                    .foregroundColor(.white)
                AsyncImage(url: logo_url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
                    default:
                        Text(org.name)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.carousel().gradient)
            .cornerRadius(15)

        } else {
            Text(org.name)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
                .background(theme.carousel().gradient)
                .cornerRadius(15)
        }
    }
}

struct OrgsView_Previews: PreviewProvider {
    static var previews: some View {
        OrgsView(title: "Vendors", tagId: 45695)
    }
}
