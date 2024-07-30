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
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("conferenceCode") var conferenceCode: String = "INIT"
    @AppStorage("showHidden") var showHidden: Bool = false
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    
    //@StateObject var cViewModel = ConferencesViewModel()
    
    var body: some View {
        if consViewModel.conferences.count > 0 {
            Text("Select Conference")
                .font(.headline)
            Divider()
            List(consViewModel.conferences, id: \.code) { conference in
                ConferenceRow(conference: conference, code: selected.code)
                    .onTapGesture {
                        if conference.code == selected.code {
                            print("Already selected \(conference.name)")
                        } else {
                            print("Selected \(conference.name)")
                            selected.code = conference.code
                            conferenceCode = conference.code
                            viewModel.fetchData(code: conference.code)
                            showLocaltime ? DateFormatterUtility.shared.update(tz: TimeZone.current) : DateFormatterUtility.shared.update(tz: TimeZone(identifier: conference.timezone ?? "America/Los_Angeles"))
                        }

                        self.presentationMode.wrappedValue.dismiss()
                    }
            }
            .analyticsScreen(name: "ConferencesView")
            .listStyle(.plain)
        } else {
            _04View(message: "Loading", show404: false).preferredColorScheme(.dark)
                .onAppear {
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
