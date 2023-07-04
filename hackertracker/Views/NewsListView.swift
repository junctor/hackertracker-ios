//
//  NewsListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import SwiftUI

struct NewsListView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    
    @State private var searchText = ""
    
    var filteredNews: [Article] {
        guard !searchText.isEmpty else {
            return viewModel.news
        }
        return viewModel.news.filter { news in
            news.name.lowercased().contains(searchText.lowercased()) || news.text.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        List {
            ForEach(self.filteredNews) { article in
                NavigationLink(destination: DocumentView(title_text: article.name, body_text: article.text)) {
                    VStack(alignment: .leading) {
                        Text(article.name)
                        
                        Text(DateFormatterUtility.shared.monthDayTimeFormatter.string(from: article.updatedAt))
                            .font(.caption2)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("News")
    }
}

struct NewsListView_Previews: PreviewProvider {
    static var previews: some View {
        NewsListView()
    }
}
