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
            List {
                if !searchText.isEmpty {
                    Section(header: Text("Schedule")) {
                        ForEach(viewModel.events.search(text: searchText).sorted {$0.beginTimestamp < $1.beginTimestamp}, id: \.id) { event in
                            NavigationLink(destination: ContentDetailView(contentId: event.contentId)) {
                                EventCell(event: event, showDay: true)
                            }
                        }
                    }

                    Section(header: Text("Speakers")) {
                        ForEach(viewModel.speakers.search(text: searchText).sorted {
                            $0.name < $1.name
                        }, id: \.id) { speaker in
                            NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                                SpeakerRow(speaker: speaker, themeColor: theme.carousel())
                            }
                        }
                    }
                    
                    Section(header: Text("Documents")) {
                        ForEach(viewModel.documents.search(text: searchText).sorted {
                            $0.title < $1.title
                        }, id: \.id) { document in
                            NavigationLink(destination: DocumentView(title_text: document.title, body_text: document.body)) {
                                docSearchRow(title_text: document.title, themeColor: colorMode ? theme.carousel() : Color(.systemGray2))
                            }
                        }
                    }

                    if let ott = self.viewModel.tagtypes.first(where: { $0.category == "orga" }) {
                        ForEach(ott.tags, id: \.id) { tag in
                            Section(header: Text(tag.label)) {
                                ForEach(self.viewModel.orgs.filter { $0.tag_ids.contains(tag.id) }.search(text: searchText).sorted {
                                    $0.name < $1.name
                                }, id: \.id) { org in
                                    NavigationLink(destination: DocumentView(title_text: org.name, body_text: org.description)) {
                                        orgSearchRow(org: org, themeColor: theme.carousel())
                                    }
                                }
                            }
                        }
                    }

                    if viewModel.faqs.count > 0 {
                        Section(header: Text("FAQ")) {
                            ForEach(self.viewModel.faqs.search(text: searchText)) { faq in
                                faqRow(faq: faq)
                            }
                        }
                    }

                    if viewModel.news.count > 0 {
                        Section(header: Text("News")) {
                            ForEach(self.viewModel.news.search(text: searchText).sorted {
                                $0.updatedAt < $1.updatedAt
                            }) { article in
                                articleRow(article: article)
                            }
                        }
                    }
                }
        }
            .listStyle(SidebarListStyle())
        .navigationTitle("Global Search")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
}
