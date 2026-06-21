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

    @ViewBuilder private var inlineSearchBar: some View {
        if isSearching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search FAQs", text: $searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search text")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder private var searchToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearching.toggle()
            }
            if isSearching {
                searchFocused = true
            } else {
                searchText = ""
            }
        } label: {
            Image(systemName: isSearching ? "xmark.circle" : "magnifyingglass")
        }
        .accessibilityLabel(isSearching ? "Close search" : "Search FAQs")
    }

    @ViewBuilder private var jumpMenu: some View {
        Menu {
            Button {
                jumpTarget = "__top"
            } label: { Label("Top", systemImage: "arrow.up") }
            Button {
                jumpTarget = "__bottom"
            } label: { Label("Bottom", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }

    var body: some View {
        VStack(spacing: 0) {
            inlineSearchBar
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
                jumpMenu
                    .font(themeManager.title2Font)
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(.regularMaterial, in: Circle())
                    .accessibilityLabel("Jump")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .navigationTitle("FAQs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                searchToggleButton
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
