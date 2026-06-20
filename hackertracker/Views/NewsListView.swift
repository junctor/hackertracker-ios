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

    @State private var searchText = ""

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var jumpTarget: String?

    private var filteredNews: [Article] {
        viewModel.news.search(text: searchText).sorted { $0.updatedAt > $1.updatedAt }
    }

    @ViewBuilder private var inlineSearchBar: some View {
        if isSearching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search news", text: $searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search text")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder private var searchToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearching.toggle()
            }
            if isSearching {
                searchFocused = true
            } else {
                searchText = ""
            }
        } label: {
            Image(systemName: isSearching ? "xmark.circle" : "magnifyingglass")
        }
        .accessibilityLabel(isSearching ? "Close search" : "Search news")
    }

    @ViewBuilder private var jumpMenu: some View {
        Menu {
            Button {
                jumpTarget = "__top"
            } label: { Label("Top", systemImage: "arrow.up") }
            Button {
                jumpTarget = "__bottom"
            } label: { Label("Bottom", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }

    var body: some View {
        VStack(spacing: 0) {
            inlineSearchBar
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
                jumpMenu
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(.regularMaterial, in: Circle())
                    .accessibilityLabel("Jump")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .navigationTitle("News")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                searchToggleButton
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
                        Text(article.name).font(.subheadline).fontWeight(.bold).multilineTextAlignment(.leading)

                        Text(DateFormatterUtility.shared.monthDayTimeFormatter.string(from: article.updatedAt))
                            .font(.caption2)
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
                        Markdown(article.text).padding(.vertical)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(ThemeColors.cardSurface)
                    .cornerRadius(15)
                } else {
                    Markdown(article.text).padding(.vertical)
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
