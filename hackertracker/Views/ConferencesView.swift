//
//  ConferencesView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/13/22.
//

import SwiftUI
import CoreData

struct ConferencesView: View {
    @ObservedObject private var viewModel = ConferencesViewModel()
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("conferenceName") var conferenceName: String = "DEF CON 30"
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @AppStorage("showHidden") var showHidden: Bool = false
    
    var body: some View {
        List(viewModel.conferences, id: \.code) { conference in
            if showHidden == false && conference.hidden == false {
                ConferenceRow(conference: conference, code: conferenceCode)
                    .onTapGesture {
                        if conference.code == conferenceCode {
                            print("Already selected \(conference.name)")
                        } else {
                            print("Tapped \(conference.name)")
                            conferenceCode = conference.code
                            conferenceName = conference.name
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
            }
        }
        .listStyle(.plain)
        .onAppear {
            self.viewModel.fetchData()
        }
        .navigationBarTitle("Select Conference", displayMode: .inline)
        .preferredColorScheme(.dark)

    }
}

struct ConferencesView_Previews: PreviewProvider {

    static var previews: some View {
        ConferencesView()
    }
}
