//
//  NewsListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import MarkdownUI
import SwiftUI

struct NewsListView: View {
    @EnvironmentObject var viewModel: InfoViewModel

    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(self.viewModel.news.search(text: searchText).sorted {
                $0.updatedAt < $1.updatedAt
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

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showText.toggle()
            }, label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(article.name).font(.subheadline).fontWeight(.bold).multilineTextAlignment(.leading)

                        Text(DateFormatterUtility.shared.monthDayTimeFormatter.string(from: article.updatedAt))
                            .font(.caption2)
                    }

                    Spacer()
                    showText ? Image(systemName: "chevron.down") : Image(systemName: "chevron.right")
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)

            if showText {
                Markdown(article.text).padding(.vertical)
            }
        }
    }
}

struct NewsListView_Previews: PreviewProvider {
    static var previews: some View {
        NewsListView()
    }
}
