//
//  GlobalSearchView.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/4/23.
//

import SwiftUI

struct GlobalSearchView: View {
    @State private var searchText = ""
    /// Perf C: debounced mirror of `searchText`. Updated on a 200ms
    /// .task(id:) so search results re-filter once per pause rather
    /// than on every keystroke.
    @State private var debouncedSearch = ""
    @EnvironmentObject var theme: Theme
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage("colorMode") var colorMode: Bool = false
    
    var body: some View {
        ScrollView {
            ScrollViewReader { _ in
                if !debouncedSearch.isEmpty {
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        Section(header: GlobalSearchHeader(headerText: "Schedule")) {
                            ForEach(viewModel.events.search(text: debouncedSearch, speakers: viewModel.speakers).sorted {$0.beginTimestamp < $1.beginTimestamp}, id: \.id) { event in
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
                                ForEach(viewModel.speakers.search(text: debouncedSearch).sorted {
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
                            ForEach(viewModel.documents.search(text: debouncedSearch).sorted {
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
                                    ForEach(self.viewModel.orgs.filter { $0.tag_ids.contains(tag.id) }.search(text: debouncedSearch).sorted {
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
                                ForEach(self.viewModel.faqs.search(text: debouncedSearch)) { faq in
                                    faqRow(faq: faq)
                                        .foregroundColor(.primary)
                                        .padding(1)
                                }
                            }
                        }

                        if viewModel.news.count > 0 {
                            Section(header: GlobalSearchHeader(headerText: "News")) {
                                ForEach(self.viewModel.news.search(text: debouncedSearch).sorted {
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
            .themedNavTitle("Global Search", themeManager)
            .task(id: searchText) {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if !Task.isCancelled { debouncedSearch = searchText }
            }
        }
    }
}

struct GlobalSearchHeader: View {
    var headerText: String
    
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Text(headerText.uppercased())
          .font(themeManager.subheadlineFont)
          .padding(3)
          .frame(maxWidth: .infinity)
          .background(themeManager.cardSurface)
    }
}
