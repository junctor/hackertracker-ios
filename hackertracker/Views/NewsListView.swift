//
//  NewsListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import MarkdownUI
import SwiftUI
import FirebaseAnalytics

struct NewsListView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager

    @State private var searchText = ""

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var jumpTarget: String?

    private var filteredNews: [Article] {
        viewModel.news.search(text: searchText).sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            InlineSearchBar(placeholder: "Search news", text: $searchText, isFocused: $searchFocused, visible: isSearching)
            ScrollView {
                if filteredNews.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "No News Yet",
                            systemImage: "newspaper",
                            description: Text("Conference articles will appear here once they're published.")
                        )
                        .padding(.top, 60)
                    } else {
                        ContentUnavailableView.search(text: searchText)
                            .padding(.top, 60)
                    }
                } else {
                    ScrollViewReader { proxy in
                        LazyVStack {
                            Color.clear.frame(height: 1).id("__top")
                            ForEach(filteredNews) { article in
                                articleRow(article: article, pad: true)
                                    .padding(2)
                            }
                            Color.clear.frame(height: 1).id("__bottom")
                        }
                        .onChange(of: jumpTarget) { _, target in
                            guard let target else { return }
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                            DispatchQueue.main.async { jumpTarget = nil }
                        }
                        // iPad: readable centered column for rows.
                        .iPadReadableContent()
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
        .navigationTitle("News")
        .themedNavTitle("News", themeManager)
        .themedBackground(themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                SearchToggleButton(isSearching: $isSearching, searchText: $searchText, isFocused: $searchFocused, searchLabel: "Search news")
            }
        }
        .analyticsScreen(name: "NewsListView")
    }
}

struct articleRow: View {
    let article: Article
    var pad: Bool = false
    @State private var showText = false
    @FetchRequest(sortDescriptors: []) var readnews: FetchedResults<News>
    @Environment(\.managedObjectContext) private var viewContext

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility tz changes.
        let _ = DateFormatterUtility.shared.tzGeneration
        VStack(alignment: .leading) {
            Button(action: {
                showText.toggle()
            }, label: {
                HStack (alignment: .top) {
                    Circle().fill(readnews.map({$0.id}).contains(Int32(article.id)) ? Color(.clear) : .blue )
                        .frame(width: 6)
                        .padding(.top, 5)
                    VStack(alignment: .leading) {
                        Text(article.name).font(themeManager.subheadlineFont).fontWeight(.bold).multilineTextAlignment(.leading)

                        Text(DateFormatterUtility.shared.monthDayTimeFormatter.string(from: article.updatedAt))
                            .font(themeManager.captionFont)
                    }
                    

                    Spacer()
                    showText ? Image(systemName: "chevron.down") : Image(systemName: "chevron.right")
                }
            })
            .buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            // .overlay(NotificationDot(showDot: !readnews.map({$0.id}).contains(Int32(article.id))))

            if showText {
                if pad {
                    VStack(alignment: .leading) {
                        Markdown(article.text).themedMarkdown(themeManager).padding(.vertical)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(themeManager.cardSurface)
                    .cornerRadius(15)
                } else {
                    Markdown(article.text).themedMarkdown(themeManager).padding(.vertical)
                }
            }
        }
        .onChange(of: showText) { _, value in 
            if value && !readnews.map({$0.id}).contains(Int32(article.id)) {
                NewsUtility.addReadNews(context: viewContext, id: article.id)
            }
        }
        .onDisappear {
            self.showText = false
        }
    }
}

struct NewsListView_Previews: PreviewProvider {
    static var previews: some View {
        NewsListView()
    }
}
