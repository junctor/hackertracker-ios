//
//  TextListView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/10/23.
//

import SwiftUI
import Firebase

struct TextListView: View {
    var type: String
    @ObservedObject private var viewModel = TextListViewModel()
    @EnvironmentObject var selected: SelectedConference

    var body: some View {
        Text(type.uppercased())
            .font(.title2)
        List {
            if type == "faqs" {
                ForEach(viewModel.faqs) { faq in
                    HStack {
                        NavigationLink(destination: DocumentView(title_text: faq.question, body_text: faq.answer)) {
                            Text(faq.question)
                        }
                    }
                }
            } else if type == "news" {
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
        }
        .onAppear {
            viewModel.fetchData(code: selected.code)
        }
    }
}

struct TextListView_Previews: PreviewProvider {
    static var previews: some View {
        TextListView(type: "faqs")
    }
}
