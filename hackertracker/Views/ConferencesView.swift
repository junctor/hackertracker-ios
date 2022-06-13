//
//  ConferencesView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/13/22.
//

import SwiftUI

struct ConferencesView: View {
    @ObservedObject private var viewModel = ConferencesViewModel()
    
    var body: some View {
        List (viewModel.conferences, id: \.code) { conference in
            if (conference.hidden == false) {
                ConferenceRow(conference: conference)
            }
        }
        .listStyle(.plain)
        .onAppear() {
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
