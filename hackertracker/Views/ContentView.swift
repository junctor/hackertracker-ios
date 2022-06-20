//
//  ContentView.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import CoreData
import Firebase
import SwiftUI

struct ContentView: View {
    @AppStorage("conferenceName") var conferenceName: String = "DEF CON 30"
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @State var conference: Conference?
    @State private var viewModel = ConferencesViewModel()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmarks.id, ascending: true)],
        animation: .default
    )
    private var bookmarksResults: FetchedResults<Bookmarks>
    @EnvironmentObject var bookmarks: oBookmarks

    private var colorScheme: ColorScheme = .dark

    var body: some View {
        NavigationView {
            TabView {
                ScheduleView()
                    .tabItem {
                        Image(systemName: "house")
                        // Text("Main")
                    }
                    .tag(1)
                    .preferredColorScheme(colorScheme)
                MapView(conference: self.conference)
                    .tabItem {
                        Image(systemName: "map")
                        // Text("Maps")
                    }
                    .tag(2)
                    .preferredColorScheme(colorScheme)

                InfoView(viewModel: self.viewModel)
                    .tabItem {
                        Image(systemName: "info.circle")
                        // Text("Info")
                    }
                    .tag(3)
                    .preferredColorScheme(colorScheme)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        // Text("Settings")
                    }
                    .tag(4)
                    .preferredColorScheme(colorScheme)
            }
            .navigationBarTitle(conferenceName)
            .navigationBarItems(leading: HStack {
                                    Button(action: {
                                        print("I'm feeling lucky ;)")
                                    }) {
                                        Text(conferenceName)
                                    }
                                }
            )
        }
        .onAppear {
            if #available(iOS 15.0, *) {
                let tabBarAppearance: UITabBarAppearance = .init()
                tabBarAppearance.configureWithDefaultBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }

            self.viewModel.fetchData()
            self.conference = self.viewModel.getConference(code: conferenceCode)
            if bookmarks.bookmarks.count < 1 {
                bookmarks.bookmarks = bookmarksResults.map { bookmark -> Int in
                    Int(bookmark.id)
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Content View Preview")
        /* Group {
             ContentView(settings: Settings()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
         } */
    }
}
