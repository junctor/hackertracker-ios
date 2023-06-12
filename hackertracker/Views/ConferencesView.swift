//
//  ConferencesView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/13/22.
//

import CoreData
import SwiftUI

struct ConferencesView: View {
    @ObservedObject private var viewModel = ConferencesViewModel()
    @EnvironmentObject var selected: SelectedConference
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @AppStorage("showHidden") var showHidden: Bool = false

    var body: some View {
        List(viewModel.conferences, id: \.code) { conference in
            if showHidden == false && conference.hidden == false {
                ConferenceRow(conference: conference, code: selected.code)
                    .onTapGesture {
                        if conference.code == selected.code {
                            print("Already selected \(conference.name)")
                        } else {
                            print("Selected \(conference.name)")
                            selected.code = conference.code
                            conferenceCode = conference.code
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
            }
        }
        .listStyle(.plain)
        .onAppear {
            self.viewModel.fetchData()
        }
        .navigationBarTitle("Change Conference", displayMode: .inline)
        .preferredColorScheme(.dark)
    }
}

struct ConferencesView_Previews: PreviewProvider {
    static var previews: some View {
        ConferencesView()
    }
}
