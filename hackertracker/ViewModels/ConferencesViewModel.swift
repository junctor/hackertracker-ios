//
//  ConferencesViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/13/22.
//

import FirebaseFirestore
import Foundation

class ConferencesViewModel: ObservableObject {
    @Published var conferences = [Conference]()

    private var db = Firestore.firestore()

    func fetchData(hidden: Bool) {
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

    func getConference(code: String) -> Conference? {
        for c in conferences where c.code == code {
            return c
        }
        return nil
    }
}
