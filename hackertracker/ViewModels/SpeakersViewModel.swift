//
//  SpeakersViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class SpeakersViewModel: ObservableObject {
    @Published var speakers = [Speaker]()
    @Published var searchText = ""
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    
    var filteredSpeakers: [Speaker] {
        guard !searchText.isEmpty else {
            return speakers
        }
        return speakers.filter { speakers in
            speakers.name.lowercased().contains(searchText.lowercased())
        }
    }

    private var db = Firestore.firestore()

    func fetchData() {
        db.collection("conferences")
            .document(conferenceCode)
            .collection("speakers").order(by: "name", descending: false).addSnapshotListener { querySnapshot, error in
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
        return Dictionary(grouping: filteredSpeakers, by: { $0.name.first ?? "-" })
    }
}
