//
//  ConferencesViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/13/22.
//

import Foundation
import FirebaseFirestore

class ConferencesViewModel: ObservableObject {
    @Published var conferences = [Conference]()
    
    private var db = Firestore.firestore()
    
    func fetchData() {
        db.collection("conferences").order(by: "start_date", descending: true).addSnapshotListener{ (querySnapshot, error) in
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
            
        }
    }
    
    func getConference(code: String) -> Conference? {
        for c in conferences {
            if c.code == code {
                return c
            }
        }
        return nil
    }
}
