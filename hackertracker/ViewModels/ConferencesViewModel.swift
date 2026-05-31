//
//  ConferencesViewModel.swift
//  hackertracker
//
//  Created by Seth Law on 7/28/23.
//

import Foundation
import FirebaseFirestore
import Observation

/// Phase 3b: migrated from ObservableObject to @Observable. SwiftUI now
/// tracks `conferences` access at the property level instead of invalidating
/// the entire view tree on any change.
// Phase 3c: @MainActor isolation. All published-state mutation now happens
// on the main actor; Firestore listener callbacks hop onto MainActor via Task.
@Observable
@MainActor
final class ConferencesViewModel {
    var conferences = [Conference]()
    /// Firestore listener kept out of the observation graph; SwiftUI doesn't
    /// need to re-render on listener handle changes.
    @ObservationIgnored nonisolated(unsafe) private var conferenceListener: ListenerRegistration?
    @ObservationIgnored private let db = Firestore.firestore()

    deinit {
        conferenceListener?.remove()
    }

    func fetchConferences(hidden: Bool) {
        guard conferenceListener == nil else { return }
        conferenceListener = db.collection("conferences")
            .whereField("hidden", isEqualTo: hidden)
            .order(by: "start_date", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, _ in
                // Decode off the listener closure (Sendable context); apply on MainActor.
                guard let documents = querySnapshot?.documents else {
                    Log.firestore.info("conferences: empty snapshot")
                    return
                }
                var cache = 0
                var firestore = 0
                let decoded: [Conference] = documents.compactMap { snap -> Conference? in
                    do {
                        if snap.metadata.isFromCache { cache += 1 } else { firestore += 1 }
                        return try snap.data(as: Conference.self)
                    } catch {
                        Log.firestore.error("conference decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeConferences"])
                        return nil
                    }
                }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.conferences = decoded
                    Log.app.debug("conferences loaded: \(decoded.count) (cache=\(cache), firestore=\(firestore))")
                }
            }
    }
}
