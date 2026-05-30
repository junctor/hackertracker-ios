//
//  EventViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/17/22.
//

import FirebaseFirestore
import Foundation
import Observation
import SwiftUI

/// Phase 3b: migrated to @Observable. Currently unused at any callsite but
/// kept as a working template for the eventual InfoViewModel split.
@Observable
final class EventViewModel {
    var event: Event?
    @ObservationIgnored private let db = Firestore.firestore()
    @ObservationIgnored private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    func fetchData(code: String, eventId: Int) {
        listener = db.collection("conferences")
            .document(code)
            .collection("events")
            .document(String(eventId))
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self else { return }
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
