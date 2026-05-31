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

    private var filteredNews: [Article] {
        viewModel.news.search(text: searchText).sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        // Phase 5a: pull-to-refresh + empty-state UX.
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
                ScrollViewReader { _ in
                    ForEach(filteredNews) { article in
                        articleRow(article: article, pad: true)
                            .padding(2)
                    }
                }
            }
        }
        .refreshable {
            if let code = viewModel.conference?.code {
                viewModel.fetchData(code: code)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("News")
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
                    .background(Color(.systemGray6))
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
