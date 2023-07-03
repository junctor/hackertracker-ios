//
//  NewsListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import SwiftUI

struct NewsListView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.news) { article in
                NavigationLink(destination: DocumentView(title_text: article.name, body_text: article.text)) {
                    VStack(alignment: .leading) {
                        Text(article.name)
                        
                        Text(DateFormatterUtility.shared.monthDayTimeFormatter.string(from: article.updatedAt))
                            .font(.caption2)
                    }
                }
            }
        }
        .navigationTitle("News")
    }
}

struct NewsListView_Previews: PreviewProvider {
    static var previews: some View {
        NewsListView()
    }
}
