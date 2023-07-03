//
//  FAQListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import SwiftUI

struct FAQListView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.faqs) { faq in
                HStack {
                    NavigationLink(destination: DocumentView(title_text: faq.question, body_text: faq.answer)) {
                        Text(faq.question)
                    }
                }
            }
        }
        .navigationTitle("FAQs")
    }
}

struct FAQListView_Previews: PreviewProvider {
    static var previews: some View {
        FAQListView()
    }
}
