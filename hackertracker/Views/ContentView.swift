//
//  ContentView.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import CoreData
import SwiftUI
import FirebaseFirestoreSwift

struct ContentView: View {
    @AppStorage("conferenceName") var conferenceName: String = "DEF CON 30"
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    
    @FirestoreQuery(collectionPath: "conferences") var conferences: [Conference]

    // @State var conference: Conference?
    // @State private var viewModel = ConferencesViewModel()
    
    private var colorScheme: ColorScheme = .dark

    var body: some View {
        NavigationView {
            TabView {
                if let con = conferences.first {
                    InfoView(conference: con)
                        .tabItem {
                            Image(systemName: "house")
                            // Text("Info")
                        }
                        .tag(3)
                        .preferredColorScheme(colorScheme)
                    
                    ScheduleView(code: con.code)
                        .tabItem {
                            Image(systemName: "calendar")
                            // Text("Main")
                        }
                        .tag(1)
                        .preferredColorScheme(colorScheme)
                    MapView()
                        .tabItem {
                            Image(systemName: "map")
                            // Text("Maps")
                        }
                        .tag(2)
                        .preferredColorScheme(colorScheme)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape")
                            // Text("Settings")
                        }
                        .tag(4)
                        .preferredColorScheme(colorScheme)
                }
            }
            // .navigationBarTitle(conferenceName, displayMode: .inline)
/*            .navigationBarItems(leading: HStack {
                                    Button(action: {
                                        print("I'm feeling lucky ;)")
                                    }) {
                                        Text(conferenceName)
                                    }
                                }
            ) */
        }
        .onAppear {
            if #available(iOS 15.0, *) {
                let tabBarAppearance: UITabBarAppearance = .init()
                tabBarAppearance.configureWithDefaultBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }

            $conferences.predicates = [.where("code", isEqualTo: conferenceCode)]
            // NSLog("ContentView: Conference - \(conferences.first?.name ?? "None found")")

            // self.viewModel.fetchData()
            // self.conference = self.viewModel.getConference(code: conferenceCode)
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
