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
    @ObservedObject private var viewModel = InfoViewModel()
    @AppStorage("launchScreen") var launchScreen: String = "Info"

    // @FirestoreQuery(collectionPath: "conferences") var conferences: [Conference]
    // var viewModel: ConferencesViewModel
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    @State var rick: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                VStack(alignment: .center) {
                    Text(conference.name)
                        .font(.largeTitle)
                        .bold()
                        .padding(.trailing, 15)
                    Text("August 4 - August 7, 2023")
                        .font(.headline)
                        .bold()
                        .padding(.trailing, 15)
                    Text("Las Vegas, NV (American/Los_Angeles")
                        .font(.subheadline)
                        .bold()
                    Divider()
                    Text("Welcome to [DEF CON](https://defcon.org/) - the largest hacker conference in the world.")
                        .font(.subheadline)
                    
                }
                .cornerRadius(15)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(.gray, lineWidth: 1)
                )
                Text("Documents")
                    .font(.subheadline)
                LazyVGrid(columns: gridItemLayout, spacing: 20) {
                    ForEach(self.viewModel.documents, id: \.id) { doc in
                        NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                            Text(doc.title)
                        }
                    }
                }
                Divider()
                Text("Searchable")
                    .font(.subheadline)
                LazyVGrid(columns: gridItemLayout, spacing: 20) {
                    NavigationLink(destination: SpeakersView()) {
                        Image(systemName: "person.crop.rectangle")
                        Text("Speakers")
                    }
                    if let ott = self.viewModel.tagtypes.first(where: { $0.category == "orga"}) {
                        ForEach(ott.tags, id: \.id) { tag in
                            NavigationLink(destination: OrgsView(title: tag.label, tagId: tag.id)) {
                                Image(systemName: "bag")
                                Text(tag.label)
                            }
                        }
                    }
                    NavigationLink(destination: TextListView(type: "faqs")) {
                        Image(systemName: "questionmark.app")
                        Text("FAQ")
                    }
                    /* NavigationLink(destination: OrgsView(title: "Vendors")) {
                        Image(systemName: "bag")
                        Text("Vendors")
                    } */
                    NavigationLink(destination: TextListView(type: "news")) {
                        Image(systemName: "newspaper")
                        Text("News")
                    }
                    /*Link(destination: URL(string: "mailto://hackertracker@defcon.org")!) {
                        Image(systemName: "square.and.pencil")
                        Text("Contact Us")
                    }*/
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
                viewModel.fetchData(code: conference.code)
                launchScreen = "Info"
                // $conferences.predicates = [.where("code", isEqualTo: conferenceCode)]
                // conference = self.viewModel.getConference(code: conferenceCode)
            }
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
