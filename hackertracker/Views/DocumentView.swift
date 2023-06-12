//
//  DocumentView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import SwiftUI
import MarkdownUI

extension String {
    func markdownToAttributed() -> AttributedString {
        do {
            return try AttributedString(markdown: self) /// convert to AttributedString
        } catch {
            return AttributedString("Error parsing markdown: \(error)")
        }
    }
}

struct DocumentView: View {
    var title_text: String
    var body_text: String
    
    var body: some View {
        ScrollView {
            VStack {
                Text(title_text)
                    .font(.title)
                    .rectangleBackground()
                Divider()
                Markdown(body_text)
                /* (body_text.markdownToAttributed())
                    .font(.body) */
            }
        }
    }
}

struct DocumentView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentView(title_text: "Title of Document", body_text: "Go ahead and add *markdown* to make things interesting if you want")
    }
}
