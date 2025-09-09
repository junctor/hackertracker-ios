//
//  FAQListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import MarkdownUI
import SwiftUI

struct FAQListView: View {
    @EnvironmentObject var viewModel: InfoViewModel

    @State private var searchText = ""

    var body: some View {
        ScrollView {
            ScrollViewReader { _ in
                ForEach(self.viewModel.faqs.search(text: searchText)) { faq in
                    faqRow(faq: faq)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("FAQs")
            .analyticsScreen(name: "FAQListView")
        }
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
