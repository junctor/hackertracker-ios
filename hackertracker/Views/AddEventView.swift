//
//  AddEventView.swift
//  hackertracker
//
//  Created by Seth Law on 7/11/23.
//

import SwiftUI

struct AddEvent: UIViewControllerRepresentable {
    var event: Event
    
    func makeUIViewController(context: Context) -> AddEventController {
        let aev = AddEventController()
        aev.setEvent(newEvent: event)
        return aev
    }
    
    func updateUIViewController(_ uiViewController: AddEventController, context: Context) {
        // We need this to follow the protocol, but don't have to implement it
        // Edit here to update the state of the view controller with information from SwiftUI
    }
}

struct AddContent: UIViewControllerRepresentable {
    var content: Content
    var session: Session
    @EnvironmentObject var viewModel: InfoViewModel
    
    func makeUIViewController(context: Context) -> AddContentController {
        let acc = AddContentController()
        acc.setContent(newEvent: content, newSession: session, newLocation: viewModel.locations.first(where: {$0.id == session.locationId}))
        return acc
    }
    
    func updateUIViewController(_ uiViewController: AddContentController, context: Context) {
        // We need this to follow the protocol, but don't have to implement it
        // Edit here to update the state of the view controller with information from SwiftUI
    }
}
