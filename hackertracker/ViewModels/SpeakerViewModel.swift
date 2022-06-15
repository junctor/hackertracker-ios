//
//  SpeakerViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class SpeakerViewModel: ObservableObject {
    @Published var speaker = Speaker(docId: nil,
                                     id: 123,
                                     conferenceName: "DEFCON 30",
                                     description: "Description of Speaker background goes here",
                                     link: "https://defcon.org/",
                                     name: "Speaker Name",
                                     title: nil,
                                     twitter: "defcon",
                                     events: [])
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    
    private var db = Firestore.firestore()#imageLiteral(resourceName: "simulator_screenshot_00801B67-EB5B-4E4C-A06F-26FD9835598F.png")
    
    func fetchData(speakerId: String) {
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
        /*
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                
                print("Current data: \(data)")
                speaker = data as Speaker
               
            } */
    }
}
