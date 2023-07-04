//
//  SpeakerViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class SpeakerViewModel: ObservableObject {
    @Published var speaker: Speaker?
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"

    private var db = Firestore.firestore()

    func fetchData(speakerId: String) {
        // Get Speakers
        db.collection("conferences")
            .document(conferenceCode)
            .collection("speakers")
            .document(speakerId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }

                do {
                    self.speaker = try document.data(as: Speaker.self)

                } catch {
                    print("Error decoding speaker data")
                }
            }
    }
}
