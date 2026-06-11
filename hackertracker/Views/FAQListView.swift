//
//  FAQListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import MarkdownUI
import SwiftUI

struct FAQListView: View {
    @Environment(InfoViewModel.self) private var viewModel

    @State private var searchText = ""

    private var filteredFaqs: [FAQ] {
        viewModel.faqs.search(text: searchText)
    }

    var body: some View {
        // Phase 5a: pull-to-refresh + empty-state UX.
        ScrollView {
            if filteredFaqs.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No FAQs",
                        systemImage: "questionmark.circle",
                        description: Text("Frequently asked questions will appear here once published.")
                    )
                    .padding(.top, 60)
                } else {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 60)
                }
            } else {
                ScrollViewReader { _ in
                    ForEach(filteredFaqs) { faq in
                        faqRow(faq: faq)
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
        .navigationTitle("FAQs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .analyticsScreen(name: "FAQListView")
    }
}

struct faqRow: View {
    let faq: FAQ
    @State private var showAnswer = false

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showAnswer.toggle()
            }, label: {
                HStack {
                    Text(faq.question).font(.subheadline).fontWeight(.bold).multilineTextAlignment(.leading)
                    Spacer()
                    showAnswer ? Image(systemName: "chevron.down") : Image(systemName: "chevron.right")
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)

            if showAnswer {
                Markdown(faq.answer).padding(.vertical)
            }
        }
    }
}

struct FAQListView_Previews: PreviewProvider {
    static var previews: some View {
        FAQListView()
    }
}
