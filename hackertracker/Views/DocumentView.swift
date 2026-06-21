//
//  DocumentView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import MarkdownUI
import SwiftUI

struct DocumentView: View {
    var title_text: String
    var body_text: String
    var color: Color?
    var systemImage: String?
    /// Polish: callers like the About screen want the title only in the nav
    /// bar (not duplicated in the scroll body). Emergency / merch-help docs
    /// still want the prominent in-body banner, so this defaults to true.
    var showInlineTitle: Bool = true
    @EnvironmentObject var theme: Theme
    @AppStorage("colorMode") var colorMode: Bool = false

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ScrollView {
            VStack {
                if showInlineTitle {
                    HStack {
                        Image(systemName: systemImage ?? "doc")
                            .frame(alignment: .leading)
                            .padding(5)
                        Text(title_text)
                            .font(themeManager.titleFont)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundColor(colorMode ? .white : .primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(15)
                    .background(color ?? (colorMode ? theme.carousel() : themeManager.cardSurface))
                    .cornerRadius(15)
                    Divider()
                }
                Markdown(body_text).themedMarkdown(themeManager)
                    .textSelection(.enabled)
                Divider()
            }
        }
        .navigationTitle(title_text)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .iPadReadableContent()
        .analyticsScreen(name: "DocumentView")
        .padding(15)
    }
}

struct docSearchRow: View {
    let title_text: String
    let themeColor: Color
    
    var body: some View {
        HStack {
            Rectangle().fill(themeColor)
                .frame(width: 6)
                .frame(maxHeight: .infinity)
            Text(title_text)
        }
    }
}

struct DocumentView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentView(title_text: "Title of Document", body_text: "Go ahead and add *markdown* to make things interesting if you want")
    }
}
