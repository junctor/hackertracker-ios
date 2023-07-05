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
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @EnvironmentObject var selected: SelectedConference
    @Environment(\.openURL) private var openURL
    @State var theme = Theme()

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
                        if let tagline = con.tagline {
                            Divider()
                            Text(tagline)
                                .font(.subheadline)
                        }
                        if let con = viewModel.conference, Date() <= con.kickoffTimestamp {
                            Divider()
                            CountdownView(start: con.startTimestamp)
                        }
                    } else {
                        Text("Loading")
                            .onAppear {
                                print("InfoView: Need to fetch data for \(selected.code)")
                                viewModel.fetchData(code: selected.code)
                            }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(15)
                .background(Color(.systemGray6))
                .cornerRadius(15)

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
                    NavigationLink(destination: GlobalSearchView(viewModel: viewModel)) {
                        CardView(systemImage: "magnifyingglass", text: "Search", color: theme.carousel())
                    }
                    NavigationLink(destination: SpeakersView(speakers: viewModel.speakers)) {
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
                    if let ott = self.viewModel.tagtypes.first(where: { $0.category == "orga" }) {
                        ForEach(ott.tags, id: \.id) { tag in
                            NavigationLink(destination: OrgsView(title: tag.label, tagId: tag.id)) {
                                CardView(systemImage: "bag", text: tag.label, color: theme.carousel())
                            }
                        }
                    }
                    if viewModel.faqs.count > 0 {
                        NavigationLink(destination: FAQListView()) {
                            CardView(systemImage: "questionmark.app", text: "FAQ", color: theme.carousel())
                        }
                    }
                    if viewModel.news.count > 0 {
                        NavigationLink(destination: NewsListView()) {
                            CardView(systemImage: "newspaper", text: "News", color: theme.carousel())
                        }
                    }
                }
                Divider()
                if let url = URL(string: "mailto:hackertracker@defcon.org") {
                    HStack {
                        Button {
                            openURL(url)
                        } label: {
                            Label("Contact Us", systemImage: "person.fill.questionmark")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(15)
                    .background(.gray.gradient)
                    .cornerRadius(15)
                    /* NavigationLink(destination: openURL(url)) {
                         CardView(systemImage: "square.and.pencil", text: "Contact Us", color: theme.carousel())
                     } */
                }
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
            .padding(5)
            .onAppear {
                print("InfoView: selectedCode: \(selected.code)")
                print("ScheduleView: Current launchscreen is: \(launchScreen)")
                launchScreen = "Main"
                viewModel.showLocaltime = showLocaltime
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
