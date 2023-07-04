//
//  FAQListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import SwiftUI

struct FAQListView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    
    @State private var searchText = ""
    
    var filteredFaqs: [FAQ] {
        guard !searchText.isEmpty else {
            return viewModel.faqs
        }
        return viewModel.faqs.filter { faqs in
            faqs.question.lowercased().contains(searchText.lowercased()) || faqs.answer.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        List {
            ForEach(self.filteredFaqs) { faq in
                HStack {
                    NavigationLink(destination: DocumentView(title_text: faq.question, body_text: faq.answer)) {
                        Text(faq.question)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("FAQs")
    }
}

struct FAQListView_Previews: PreviewProvider {
    static var previews: some View {
        FAQListView()
    }
}
