//
//  EventViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/17/22.
//

import Foundation
import FirebaseFirestore
import Foundation
import SwiftUI

class EventViewModel: ObservableObject {
    @Published var event: Event?
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"

    private var db = Firestore.firestore()

    func fetchData(eventId: String) {
        db.collection("conferences")
            .document(conferenceCode)
            .collection("events")
            .document(eventId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }

                do {
                    self.event = try document.data(as: Event.self)
                } catch {
                    print("Error decoding speaker data")
                }
            }
    }
}
