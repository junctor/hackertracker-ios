//
//  InfoView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        NavigationView {
            NavigationLink(destination: Text("Another View")) {
                Text("Hello, World!")
            }
            .navigationTitle("Info")
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}
