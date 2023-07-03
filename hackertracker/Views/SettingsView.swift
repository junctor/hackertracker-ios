//
//  SettingsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("launchScreen") var launchScreen: String = "Settings"

    var body: some View {
        VStack {
            NavigationLink(destination: ConferencesView(conferences: [])) {
                Text("Select Conference")
            }
        }
        .onAppear {
            launchScreen = "Settings"
        }
        // ConferencesView()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
