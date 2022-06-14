//
//  ScheduleViewModel.swift
//  hackertracker
//
//  Created by Seth Law on 6/13/22.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class ScheduleViewModel: ObservableObject {
    @Published var events = [Event]()
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    
    private var db = Firestore.firestore()
    
    func fetchData() {
        db.collection("conferences")
            .document(conferenceCode)
            .collection("events").order(by: "begin", descending: false).addSnapshotListener{ (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No Events")
                return
            }
            
            self.events = documents.compactMap { queryDocumentSnapshot -> Event? in
                do {
                    return try queryDocumentSnapshot.data(as: Event.self)
                } catch {
                    print("Error \(error)")
                    return nil
                }
                
            }
            
        }
    }
}
