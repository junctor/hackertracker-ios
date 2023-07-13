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
