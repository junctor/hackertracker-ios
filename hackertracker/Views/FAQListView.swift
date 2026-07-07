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
    @Environment(ThemeManager.self) private var themeManager

    @State private var searchText = ""

    // Polish parity with schedule / All Content.
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    @State private var jumpTarget: String?

    private var filteredFaqs: [FAQ] {
        viewModel.faqs.search(text: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            InlineSearchBar(placeholder: "Search FAQs", text: $searchText, isFocused: $searchFocused, visible: isSearching)
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
                    ScrollViewReader { proxy in
                        LazyVStack {
                            Color.clear.frame(height: 1).id("__top")
                            ForEach(filteredFaqs) { faq in
                                faqRow(faq: faq)
                            }
                            Color.clear.frame(height: 1).id("__bottom")
                        }
                        .onChange(of: jumpTarget) { _, target in
                            guard let target else { return }
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                            DispatchQueue.main.async { jumpTarget = nil }
                        }
                        // iPad: readable centered column for rows.
                        .iPadReadableContent()
                    }
                }
            }
            .refreshable {
                if let code = viewModel.conference?.code {
                    viewModel.fetchData(code: code)
                }
            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                Spacer()
                JumpMenuOverlay(target: $jumpTarget)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .navigationTitle("FAQs")
        .themedNavTitle("FAQs", themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                SearchToggleButton(isSearching: $isSearching, searchText: $searchText, isFocused: $searchFocused, searchLabel: "Search FAQs")
            }
        }
        .analyticsScreen(name: "FAQListView")
    }
}

struct faqRow: View {
    let faq: FAQ
    @Environment(ThemeManager.self) private var themeManager
    @State private var showAnswer = false

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showAnswer.toggle()
            }, label: {
                HStack {
                    Text(faq.question).font(themeManager.subheadlineFont).fontWeight(.bold).multilineTextAlignment(.leading)
                    Spacer()
                    showAnswer ? Image(systemName: "chevron.down") : Image(systemName: "chevron.right")
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)

            if showAnswer {
                Markdown(faq.answer).themedMarkdown(themeManager).padding(.vertical)
            }
        }
    }
}

struct FAQListView_Previews: PreviewProvider {
    static var previews: some View {
        FAQListView()
    }
}
