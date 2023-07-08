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
    @EnvironmentObject var theme: Theme

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(title_text)
                        .font(.title)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
                .background(theme.carousel().gradient)
                .cornerRadius(15)
                Divider()
                Markdown(body_text)
                Divider()
            }
        }
        .padding(5)
    }
}

struct DocumentView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentView(title_text: "Title of Document", body_text: "Go ahead and add *markdown* to make things interesting if you want")
    }
}
