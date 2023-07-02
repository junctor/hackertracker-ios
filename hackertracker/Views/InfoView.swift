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
    // var conference: Conference
    @ObservedObject private var viewModel = InfoViewModel()
    @AppStorage("launchScreen") var launchScreen: String = "Info"
    @EnvironmentObject var selected: SelectedConference
    var theme = Theme()

    // @FirestoreQuery(collectionPath: "conferences") var conferences: [Conference]
    // var viewModel: ConferencesViewModel
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    @State var rick: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                VStack(alignment: .center) {
                    if let con = viewModel.conference {
                        NavigationLink(destination: ConferencesView()) {
                            Text(con.name)
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            Image(systemName: "chevron.right")
                        }
                        if con.startDate == con.endDate {
                            Text(DateFormatterUtility.shared.monthDayYearFormatter.string(from: con.endTimestamp))
                                .font(.headline)
                                .bold()
                                .padding(.trailing, 15)
                        } else {
                            Text("\(DateFormatterUtility.shared.monthDayFormatter.string(from: con.startTimestamp)) - \(DateFormatterUtility.shared.monthDayYearFormatter.string(from: con.endTimestamp))")
                                .font(.headline)
                                .bold()
                                .padding(.trailing, 15)
                        }
                        if let tz = con.timezone {
                            Text(tz)
                                .font(.subheadline)
                                .bold()
                        }
                        if let tagline = con.tagline {
                            Divider()
                            Text(tagline)
                                .font(.subheadline)
                        }
                    } else {
                        Text("Loading")
                            .onAppear {
                                print("InfoView: Need to fetch data for \(selected.code)")
                                viewModel.fetchData(code: selected.code)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .cornerRadius(15)
                .padding(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(.gray, lineWidth: 1)
                )
                if self.viewModel.documents.count > 0 {
                    Text("Documents")
                        .font(.subheadline)
                    LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 20) {
                        ForEach(self.viewModel.documents, id: \.id) { doc in
                            NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                                CardView(systemImage: "doc", text: doc.title, color: theme.carousel())
                            }
                        }
                    }
                    Divider()
                }
                Text("Searchable")
                    .font(.subheadline)
                LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 20) {
                    NavigationLink(destination: Text("Global Search")) {
                        CardView(systemImage: "magnifyingglass", text: "Search", color: theme.carousel())
                    }
                    NavigationLink(destination: SpeakersView()) {
                        CardView(systemImage: "person.crop.rectangle", text: "Speakers", color: theme.carousel())
                    }
                    if self.viewModel.products.count > 0 {
                        NavigationLink(destination: ProductsView(title: "Merch", products: self.viewModel.products)) {
                            CardView(systemImage: "cart", text: "Merch", color: theme.carousel())
                        }
                    }
                    if self.viewModel.locations.count > 0 {
                        NavigationLink(destination: LocationView(locations: self.viewModel.locations)) {
                            CardView(systemImage: "mappin.and.ellipse", text: "Locations", color: theme.carousel())
                        }
                    }
                    if let ott = self.viewModel.tagtypes.first(where: { $0.category == "orga"}) {
                        ForEach(ott.tags, id: \.id) { tag in
                            NavigationLink(destination: OrgsView(title: tag.label, tagId: tag.id)) {
                                CardView(systemImage: "bag", text: tag.label, color: theme.carousel())
                            }
                        }
                    }
                    NavigationLink(destination: TextListView(type: "faqs")) {
                        CardView(systemImage: "questionmark.app", text: "FAQ", color: theme.carousel())
                    }
                    NavigationLink(destination: TextListView(type: "news")) {
                        CardView(systemImage: "newspaper", text: "News", color: theme.carousel())
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
                print("InfoView: selectedCode: \(selected.code)")
                viewModel.fetchData(code: selected.code)
                launchScreen = "Info"
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

struct CardView: View {
    var systemImage: String
    var text: String
    var color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
            Text(text)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(15)
        .background(color.gradient)
        .cornerRadius(15)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Info View")
    }
}
