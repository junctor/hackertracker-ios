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
    @EnvironmentObject var viewModel: InfoViewModel

    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(self.viewModel.news.search(text: searchText).sorted {
                $0.updatedAt > $1.updatedAt
            }) { article in
                articleRow(article: article)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("News")
        .analyticsScreen(name: "NewsListView")
    }
}

struct articleRow: View {
    let article: Article
    @State private var showText = false
    @FetchRequest(sortDescriptors: []) var readnews: FetchedResults<News>
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
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
                Markdown(article.text).padding(.vertical)
            }
        }
        .onChange(of: showText) { value in
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
