//
//  InfoView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct InfoView: View {
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid (columns: gridItemLayout, spacing: 20) {
            NavigationLink(destination: Text("Speakers List goes here")) {
                Text("Speakers!")
            }
            
            NavigationLink(destination: Text("Code of Conduct goes here")) {
                Text("Code of Conduct")
            }
            
            NavigationLink(destination: Text("Frequently Asked Questions")) {
                Text("FAQ")
            }
            NavigationLink(destination: Text("Vendors")) {
                Text("Vendors")
            }
            NavigationLink(destination: Text("News")) {
                Text("News")
            }
            NavigationLink(destination: Text("Contact Us")) {
                Text("Contact Us")
            }
        }
        .navigationTitle("Info")
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}
