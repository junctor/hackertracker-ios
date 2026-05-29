//
//  EventViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/17/22.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class EventViewModel: ObservableObject {
    @Published var event: Event?

    private var db = Firestore.firestore()

    func fetchData(code: String, eventId: Int) {
        db.collection("conferences")
            .document(code)
            .collection("events")
            .document(String(eventId))
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    Log.firestore.error("event fetch failed: \(String(describing: error), privacy: .public)")
                    if let e = error { CrashReport.record(e, context: ["op": "fetchEvent"]) }
                    return
                }

                do {
                    self.event = try document.data(as: Event.self)
                } catch {
                    Log.firestore.error("event decode failed")
                }
            }
    }
}
