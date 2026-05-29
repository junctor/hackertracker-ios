//
//  ConferencesViewModel.swift
//  hackertracker
//
//  Created by Seth Law on 7/28/23.
//

import Foundation
import FirebaseFirestore

class ConferencesViewModel: ObservableObject {
    @Published var conferences = [Conference]()
    var conferenceListener: ListenerRegistration?
    
    private var db = Firestore.firestore()
    
    func fetchConferences(hidden: Bool) {
        if let _ = conferenceListener {
            //NSLog("Conference Listener already exists")
        } else {
            conferenceListener = db.collection("conferences")
                .whereField("hidden", isEqualTo: hidden)
                .order(by: "start_date", descending: true).addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        Log.firestore.info("conferences: empty snapshot")
                        return
                    }
                    var cache = 0
                    var firestore = 0
                    self.conferences = documents.compactMap { queryDocumentSnapshot -> Conference? in
                        do {
                            if queryDocumentSnapshot.metadata.isFromCache {
                                cache = cache + 1
                            } else {
                                firestore = firestore + 1
                            }
                            return try queryDocumentSnapshot.data(as: Conference.self)
                        } catch {
                            Log.firestore.error("conference decode failed: \(error, privacy: .public)")
                            CrashReport.record(error, context: ["op": "decodeConferences"])
                            return nil
                        }
                    }
                    Log.app.debug("conferences loaded: \(self.conferences.count) (cache=\(cache), firestore=\(firestore))")
                }
        }
    }

}
