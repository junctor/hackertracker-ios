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
                        print("No Conferences")
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
                            print("Error \(error)")
                            return nil
                        }
                    }
                    print("ConferencesViewModel: \(self.conferences.count) conferences (cache hits \(cache), firestore hits \(firestore))")
                }
        }
    }

}
