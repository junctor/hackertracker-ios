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
    @EnvironmentObject var theme: Theme
    @AppStorage("colorMode") var colorMode: Bool = false

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Image(systemName: systemImage ?? "doc")
                        .frame(alignment: .leading)
                        .padding(5)
                    Text(title_text)
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(colorMode ? .white : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
                .background(color ?? (colorMode ? theme.carousel() : Color(.systemGray6)))
                .cornerRadius(15)
                Divider()
                Markdown(body_text)
                    .textSelection(.enabled)
                Divider()
            }
        }
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
