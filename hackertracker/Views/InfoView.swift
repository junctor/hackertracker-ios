//
//  InfoView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestoreSwift
import SwiftUI
import WebKit

struct InfoView: View {
    var conference: Conference
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @AppStorage("launchScreen") var launchScreen: String = "Info"

    // @FirestoreQuery(collectionPath: "conferences") var conferences: [Conference]
    // var viewModel: ConferencesViewModel
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    @State var rick: Int = 0

    var body: some View {
        VStack {
            Text(conference.name)
                .font(.title)
            Divider()
            LazyVGrid(columns: gridItemLayout, spacing: 20) {
                NavigationLink(destination: SpeakersView()) {
                    Image(systemName: "person.crop.rectangle")
                    Text("Speakers")
                }
                if let coc = conference.coc {
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
                Link(destination: URL(string: "mailto://hackertracker@defcon.org")!) {
                    Image(systemName: "square.and.pencil")
                    Text("Contact Us")
                }
            }
            Divider()
            if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("#hackertracker iOS v\(v)")
                    .font(.caption2)
                    .onTapGesture {
                        tapped()
                    }
            } else {
                Text("#hackertracker iOS")
                    .font(.caption2)
                    .onTapGesture {
                        tapped()
                    }
            }
        }
        .onAppear {
            // $conferences.predicates = [.where("code", isEqualTo: conferenceCode)]
            // conference = self.viewModel.getConference(code: conferenceCode)
        }
    }

    func tapped() {
        rick += 1
        if rick >= 7 {
            print("Roll away!")
            rick = 0
            // Implement Rick
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Info View")
    }
}

struct WebView: UIViewRepresentable {
    var url: URL

    func makeUIView(context _: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context _: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
