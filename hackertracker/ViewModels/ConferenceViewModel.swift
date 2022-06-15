//
//  ConferenceViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/14/22.
//

import Foundation
import FirebaseFirestore

class ConferenceViewModel: ObservableObject {
    /*@Published var conference: Conference? = nil
    
    private var db = Firestore.firestore()
    
    func fetchConference(code: String) {
        db.collection("conferences").document("code", isEqualTo: code).addSnapshotListener { (querySnapshot, error) in
            guard let document = querySnapshot?.documents else {
                print("No conforence with code \(code) found.")
                return
            }
            self.conference = documents.items.first
        }
        
        /*
         let docRef = db.collection("Restaurants").document("PizzaMania")

             docRef.getDocument { (document, error) in
                 guard error == nil else {
                     print("error", error ?? "")
                     return
                 }

                 if let document = document, document.exists {
                     let data = document.data()
                     if let data = data {
                         print("data", data)
                         self.restaurant = data["name"] as? String ?? ""
                     }
                 }
         */
    }*/
}
