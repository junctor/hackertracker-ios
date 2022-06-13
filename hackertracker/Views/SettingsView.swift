//
//  SettingsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            NavigationLink(destination: ConferencesView()) {
                Text("Select Conference")
            }
        }
            //ConferencesView()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
