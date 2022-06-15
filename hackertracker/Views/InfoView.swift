//
//  InfoView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct InfoView: View {
    var viewModel: ConferencesViewModel
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]
    @State var conference: Conference?
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"

    var body: some View {
        VStack {
            Text("Info")
                .font(.title)
            Divider()
            if let con = conference {
                LazyVGrid(columns: gridItemLayout, spacing: 20) {
                    NavigationLink(destination: Text("Speakers List goes here")) {
                        Image(systemName: "person.crop.rectangle")
                        Text("Speakers")
                    }
                    if let coc = con.coc {
                        NavigationLink(destination: CodeOfConductView(codeofconduct: coc)) {
                            Image(systemName: "doc")
                            Text("Code of Conduct")
                        }
                    }
                    
                    NavigationLink(destination: Text("Frequently Asked Questions")) {
                        Image(systemName: "questionmark.app")
                        Text("FAQ")
                    }
                    NavigationLink(destination: Text("Vendors")) {
                        Image(systemName: "bag")
                        Text("Vendors")
                    }
                    NavigationLink(destination: Text("News")) {
                        Image(systemName: "newspaper")
                        Text("News")
                    }
                    NavigationLink(destination: Text("Contact")) {
                        Image(systemName: "square.and.pencil")
                        Text("Contact")
                    }
                }
                Divider()
                Text(con.name).font(.caption2)
            }
        }
        .onAppear {
            conference = self.viewModel.getConference(code: conferenceCode)
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Info View")
    }
}
