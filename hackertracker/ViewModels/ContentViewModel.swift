//
//  ContentViewModel.swift
//  hackertracker
//
//  Created by Seth Law on 6/21/23.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var conference: Conference?
    
    private var db = Firestore.firestore()
    
    func fetchData(code: String) {
        db.collection("conferences").whereField("code", isEqualTo: code)
            .addSnapshotListener { querySnapshot, error in
                DispatchQueue.main.async {
                    
                    guard let docs = querySnapshot?.documents else {
                        print("No Documents")
                        return
                    }
                    
                    let conferences = docs.compactMap { queryDocumentSnapshot -> Conference? in
                        do {
                            return try queryDocumentSnapshot.data(as: Conference.self)
                        } catch {
                            print("Error \(error)")
                            return nil
                        }
                    }
                    self.conference = conferences.first
                    print("ContentViewModel: \(self.conference?.name ?? "No conference found") ")
                }
                
                // NSLog("InfoViewModel: Documents: \(self.documents.count)")
            }
    }
}
