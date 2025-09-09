//
//  GlobalSearchView.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/4/23.
//

import SwiftUI

struct GlobalSearchView: View {
    @State private var searchText = ""
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("colorMode") var colorMode: Bool = false
    
    var body: some View {
        ScrollView {
            ScrollViewReader { _ in
                if !searchText.isEmpty {
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        Section(header: GlobalSearchHeader(headerText: "Schedule")) {
                            ForEach(viewModel.events.search(text: searchText).sorted {$0.beginTimestamp < $1.beginTimestamp}, id: \.id) { event in
                                NavigationLink(destination: ContentDetailView(contentId: event.contentId)) {
                                    EventCell(event: event, showDay: true)
                                        .id(event.id)
                                        .foregroundColor(.primary)
                                        .padding(1)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Section(header: GlobalSearchHeader(headerText: "Speakers")) {
                                ForEach(viewModel.speakers.search(text: searchText).sorted {
                                    $0.name < $1.name
                                }, id: \.id) { speaker in
                                    NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                                        SpeakerRow(speaker: speaker, themeColor: theme.carousel())
                                            .id(speaker.id)
                                            .foregroundColor(.primary)
                                            .padding(1)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                        
                        Section(header: GlobalSearchHeader(headerText: "Documents")) {
                            ForEach(viewModel.documents.search(text: searchText).sorted {
                                $0.title < $1.title
                            }, id: \.id) { document in
                                NavigationLink(destination: DocumentView(title_text: document.title, body_text: document.body)) {
                                    docSearchRow(title_text: document.title, themeColor: colorMode ? theme.carousel() : Color(.systemGray2))
                                        .foregroundColor(.primary)
                                        .padding(1)
                                }
                            }
                        }
                        
                        if let ott = self.viewModel.tagtypes.first(where: { $0.category == "orga" }) {
                            ForEach(ott.tags, id: \.id) { tag in
                                Section(header: GlobalSearchHeader(headerText: tag.label)) {
                                    ForEach(self.viewModel.orgs.filter { $0.tag_ids.contains(tag.id) }.search(text: searchText).sorted {
                                        $0.name < $1.name
                                    }, id: \.id) { org in
                                        NavigationLink(destination: DocumentView(title_text: org.name, body_text: org.description)) {
                                            orgSearchRow(org: org, themeColor: theme.carousel())
                                                .foregroundColor(.primary)
                                                .padding(1)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if viewModel.faqs.count > 0 {
                            Section(header: GlobalSearchHeader(headerText: "FAQ")) {
                                ForEach(self.viewModel.faqs.search(text: searchText)) { faq in
                                    faqRow(faq: faq)
                                        .foregroundColor(.primary)
                                        .padding(1)
                                }
                            }
                        }
                        
                        if viewModel.news.count > 0 {
                            Section(header: GlobalSearchHeader(headerText: "News")) {
                                ForEach(self.viewModel.news.search(text: searchText).sorted {
                                    $0.updatedAt < $1.updatedAt
                                }) { article in
                                    articleRow(article: article)
                                        .foregroundColor(.primary)
                                        .padding(1)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Global Search")
        }
    }
}

struct GlobalSearchHeader: View {
    var headerText: String
    
    var body: some View {
        Text(headerText.uppercased())
          .font(.subheadline)
          .padding(3)
          .frame(maxWidth: .infinity)
          .background(Color(.systemGray6))
    }
}
