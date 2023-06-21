//
//  ScheduleViewModel.swift
//  hackertracker
//
//  Created by Seth Law on 6/13/22.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class ScheduleViewModel: ObservableObject {
    @Published var events = [Event]()
    @Published var conference: Conference?

    private var db = Firestore.firestore()

    func fetchData(code: String) {
        db.collection("conferences").whereField("code", isEqualTo: code)
            .addSnapshotListener { querySnapshot, error in
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
                // NSLog("InfoViewModel: Documents: \(self.documents.count)")
            }
        
        db.collection("conferences/\(code)/events")
            .order(by: "begin", descending: false).addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No Events")
                    // NSLog("No Events found!!")
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
                print("ScheduleViewModel: Events for \(code): \(self.events.count)")
            }
    }

    func eventGroup() -> [String: [Event]] {
        let eventDict = Dictionary(grouping: events, by: { dateSection(date: $0.beginTimestamp) })
        // NSLog("Event Groups: \(eventDict.count)")
        return eventDict
    }

    func eventTabs() -> [String] {
        // NSLog("eventTabs - Total Events: \(self.events.count)")
        let tabs = Array(Set(events.map { dateTabs(date: $0.beginTimestamp) })).sorted {
            (tabToDate(date: $0) ?? Date()) < (tabToDate(date: $1) ?? Date())
        }
        return tabs
    }
}
