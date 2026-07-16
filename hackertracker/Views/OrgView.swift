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
    // @Binding var tappedScheduleTwice: Bool
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var filters: Filters
    @AppStorage(AppStorageKeys.colorMode) var colorMode: Bool = false
    @Binding var tabSelection: Int

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(org.name)
                        .font(themeManager.titleFont)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(themeManager.cardSurface)
                .cornerRadius(15)
                Divider()
                if org.media.count > 0 {
                    HStack {
                        ForEach(org.media, id: \.assetId) { m in
                            if let url = URL(string: m.url) {
                                KFImage(url)
                                    .htDownsampled(side: 300)
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
                Markdown(org.description).themedMarkdown(themeManager)
                if let org_tag_id = org.tag_id_as_organizer, viewModel.events.first(where: { $0.tagIds.contains(org_tag_id)}) != nil {
                    Button {
                        if filters.filters != [org_tag_id] {
                            filters.filters = [org_tag_id]
                        }
                        tabSelection = 2
                    } label: {
                        Label("Schedule", systemImage: "calendar")
                            .foregroundColor(colorMode ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(colorMode ? themeManager.carouselColor(forKey: org.id ?? org.name) : themeManager.cardSurface)
                            .cornerRadius(15)
                    }
                }

                Divider()
                if org.links.count > 0 {
                    showLinks(links: org.links)
                }
            }
        }
        .padding(5)
        .themedBackground(themeManager)
        .analyticsScreen(name: "OrgView")
    }
}

struct showLinks: View {
    var links: [Link]
    @Environment(\.openURL) private var openURL
    @State private var collapsed = false
    @AppStorage(AppStorageKeys.colorMode) var colorMode: Bool = false

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text("Links")
                        .font(themeManager.headingFont)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if collapsed {
                        Text("Show")
                            .foregroundColor(.secondary)
                            .font(themeManager.subheadlineFont)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Hide")
                            .foregroundStyle(.secondary)
                            .font(themeManager.subheadlineFont)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }                }
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
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(colorMode ? themeManager.carouselColor(forKey: link.url) : themeManager.cardSurface)
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
