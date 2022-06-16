//
//  SpeakersViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class SpeakersViewModel: ObservableObject {
    @Published var speakers = [Speaker]()
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    
    private var db = Firestore.firestore()
    
    func fetchData() {
        db.collection("conferences")
            .document(conferenceCode)
            .collection("speakers").order(by: "name", descending: false).addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No Events")
                return
            }
            
            self.speakers = documents.compactMap { queryDocumentSnapshot -> Speaker? in
                do {
                    return try queryDocumentSnapshot.data(as: Speaker.self)
                } catch {
                    print("Error \(error)")
                    return nil
                }
                
            }
            
        }
    }

    func speakerGroup() -> [String.Element: [Speaker]] {
        return Dictionary(grouping: speakers, by: { $0.name.first ?? "-" })
    }
}
