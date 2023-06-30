//
//  MoreMenu.swift
//
//  Created by Caleb Kinney on 5/17/23.
//

import SwiftUI

struct MoreMenu: View {
    let event: Event

    var body: some View {
        Menu {
            ShareView(event: event, title: true)
            Button {} label: {
                Label("Save to Calendar", systemImage: "calendar")
            }
            Button {} label: {
                Label("Alert", systemImage: "bell")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}
