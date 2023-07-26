//
//  OrgsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import FirebaseFirestoreSwift
import SwiftUI
import Kingfisher

struct OrgsView: View {
    var title: String
    var tagId: Int
    @Binding var tappedTwice: Bool
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var selected: SelectedConference
    @State private var searchText = ""

    let gridItemLayout = [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 20) {
                ForEach(self.viewModel.orgs.filter { $0.tag_ids.contains(tagId) }.search(text: searchText), id: \.id) { org in
                    NavigationLink(destination: OrgView(org: org, tappedScheduleTwice: $tappedTwice)) {
                        orgRow(org: org, theme: theme)
                    }
                }
            }
        }
        .navigationTitle(title)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
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

    var body: some View {
        if let l = org.logo, let lurl = l.url, let logo_url = URL(string: lurl) {
            VStack {
                Text(org.name)
                    .font(.caption)
                    .foregroundColor(.white)
                KFImage(logo_url)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(15)
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
        Text("OrgsView")
        // OrgsView(title: "Vendors", tagId: 45695)
    }
}
