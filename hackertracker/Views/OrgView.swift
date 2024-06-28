//
//  OrgView.swift
//  hackertracker
//
//  Created by Seth W Law on 7/10/23.
//

import Kingfisher
import MarkdownUI
import SwiftUI

struct OrgView: View {
    var org: Organization
    @Binding var tappedScheduleTwice: Bool
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @State var schedule = UUID()

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(org.name)
                        .font(.title)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                Divider()
                if org.media.count > 0 {
                    HStack {
                        ForEach(org.media, id: \.assetId) { m in
                            if let url = URL(string: m.url) {
                                KFImage(url)
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(15)
                                    .padding(.leading, 15)
                                    .padding(.trailing, 15)
                            }
                        }
                    }
                }
                Markdown(org.description)
                if let org_tag_id = org.tag_id_as_organizer, viewModel.events.first(where: { $0.tagIds.contains(org_tag_id)}) != nil {
                    NavigationLink(destination: ScheduleView(tagId: org_tag_id, includeNav: false, navTitle: org.name, tappedScheduleTwice: $tappedScheduleTwice, schedule: $schedule)) {
                        Label("Events", systemImage: "calendar")
                        
                    }.buttonStyle(.plain)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(theme.carousel())
                        .cornerRadius(15)
                }

                Divider()
                if org.links.count > 0 {
                    showLinks(links: org.links)
                }
            }
        }
        .padding(5)
        .analyticsScreen(name: "OrgView")
    }
}

struct showLinks: View {
    var links: [Link]
    @Environment(\.openURL) private var openURL
    @State private var collapsed = false
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text("Links")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    collapsed ? Image(systemName: "chevron.right") : Image(systemName: "chevron.down")
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            if !collapsed {
                VStack(alignment: .leading) {
                    ForEach(links, id: \.label) { link in
                        if let url = URL(string: link.url) {
                            Button {
                                openURL(url)
                            } label: {
                                if link.label != "" {
                                    Label(link.label, systemImage: "arrow.up.right.square")
                                } else {
                                    Label(link.url, systemImage: "link")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(theme.carousel())
                            .cornerRadius(15)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct OrgView_Preview: PreviewProvider {
    static var previews: some View {
        DocumentView(title_text: "Title of Document", body_text: "Go ahead and add *markdown* to make things interesting if you want")
    }
}
