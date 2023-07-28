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
    
    private var db = Firestore.firestore()
    
    func fetchConferences(hidden: Bool) {
        db.collection("conferences")
            .whereField("hidden", isEqualTo: hidden)
            .order(by: "start_date", descending: true).addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No Conferences")
                    return
                }

                self.conferences = documents.compactMap { queryDocumentSnapshot -> Conference? in
                    do {
                        return try queryDocumentSnapshot.data(as: Conference.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                print("ConferencesViewModel: \(self.conferences.count) conferences")
            }
    }

}
