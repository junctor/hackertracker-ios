//
//  ConferencesView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/13/22.
//

import CoreData
import FirebaseStorage
import SwiftUI

struct ConferencesView: View {
    // var conferences: [Conference]
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var consViewModel: ConferencesViewModel
    @EnvironmentObject var filters: Filters
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("conferenceCode") var conferenceCode: String = "INIT"
    @AppStorage("showHidden") var showHidden: Bool = false
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    
    //@StateObject var cViewModel = ConferencesViewModel()
    
    var body: some View {
        if consViewModel.conferences.count > 0 {
            Text("Select Conference")
                .font(.headline)
            Divider()
            List(consViewModel.conferences, id: \.code) { conference in
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                    if conference.code == selected.code {
                        print("Already selected \(conference.name)")
                    } else {
                        print("Selected \(conference.name)")
                        selected.code = conference.code
                        conferenceCode = conference.code
                        filters.filters.removeAll()
                        viewModel.fetchData(code: conference.code)
                        showLocaltime ? DateFormatterUtility.shared.update(tz: TimeZone.current) : DateFormatterUtility.shared.update(tz: TimeZone(identifier: conference.timezone ?? "America/Los_Angeles"))
                    }
                    
                }) {
                    ConferenceRow(conference: conference, code: selected.code)
                }
                    
            }
            .analyticsScreen(name: "ConferencesView")
            .listStyle(.plain)
        } else {
            _04View(message: "Loading", show404: false).preferredColorScheme(.dark)
                .task {
                    consViewModel.fetchConferences(hidden: showHidden)
                }
        }
    }
}

struct ConferencesView_Previews: PreviewProvider {
    static var previews: some View {
        Text("ConferencesView")
        // ConferencesView()
    }
}
