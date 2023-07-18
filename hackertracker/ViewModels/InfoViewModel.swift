//
//  InfoViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/23.
//

import FirebaseFirestore
import Foundation
import FirebaseStorage
import SwiftUI

class InfoViewModel: ObservableObject {
    @Published var conference: Conference?
    @Published var conferences = [Conference]()
    @Published var documents = [Document]()
    @Published var tagtypes = [TagType]()
    @Published var locations = [Location]()
    @Published var products = [Product]()
    @Published var events = [Event]()
    @Published var speakers = [Speaker]()
    @Published var orgs = [Organization]()
    @Published var faqs = [FAQ]()
    @Published var news = [Article]()
    @Published var showLocaltime = false
    @Published var showPastEvents = true
    @Published var showNews = true

    private var db = Firestore.firestore()

    func fetchData(code: String, hidden: Bool = false) {
        fetchConference(code: code)
        fetchConferences(hidden: hidden)
        fetchDocuments(code: code)
        fetchTagTypes(code: code)
        fetchLocations(code: code)
        fetchProducts(code: code)
        fetchEvents(code: code)
        fetchSpeakers(code: code)
        fetchOrgs(code: code)
        fetchLists(code: code)
    }

    func fetchConference(code: String) {
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
                print("InfoViewModel: Conference selected: \(self.conference?.name ?? "none")")
                if let conference = self.conference, let maps = conference.maps, maps.count > 0 {
                    let fileManager = FileManager.default
                    let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let storageRef = Storage.storage().reference()
                    
                    for map in maps {
                        if let file = map.file {
                            let path = "\(conference.code)/\(file)"
                            let mRef = storageRef.child(path)
                            let mLocal = docDir.appendingPathComponent(path)
                            if fileManager.fileExists(atPath: mLocal.path) {
                                // Add logic to check md5 hash and re-update if it has changed
                                print("InfoViewModel: (\(conference.code): Map file (\(path)) already exists")
                            } else {
                                _ = mRef.write(toFile: mLocal) { _, error in
                                    if let error = error {
                                        print("InfoViewModel: (\(conference.code)): Error \(error) retrieving \(path)")
                                    } else {
                                        print("InfoViewModel: (\(conference.code)): Got map \(path)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }

    func fetchConferences(hidden: Bool) {
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
                print("InfoViewModel: \(self.conferences.count) conferences")
            }
    }

    func fetchDocuments(code: String) {
        db.collection("conferences/\(code)/documents")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.documents = docs.compactMap { queryDocumentSnapshot -> Document? in
                    do {
                        return try queryDocumentSnapshot.data(as: Document.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                print("InfoViewModel: \(self.documents.count) documents")
            }
    }

    func fetchTagTypes(code: String) {
        db.collection("conferences/\(code)/tagtypes")
            .order(by: "sort_order", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Tags")
                    return
                }

                self.tagtypes = docs.compactMap { queryDocumentSnapshot -> TagType? in
                    do {
                        return try queryDocumentSnapshot.data(as: TagType.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                print("InfoViewModel: \(self.tagtypes.count) tags")
            }
    }

    func fetchLocations(code: String) {
        db.collection("conferences/\(code)/locations")
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Locations")
                    return
                }

                self.locations = docs.compactMap { queryDocumentSnapshot -> Location? in
                    do {
                        return try queryDocumentSnapshot.data(as: Location.self)
                    } catch {
                        print("fetchLocations: Location Parsing Error: \(error)")
                        print("fetchLocations: Code: \(code)")
                        print("fetchLocations: qds: \(queryDocumentSnapshot.data())")
                        return nil
                    }
                }
                print("InfoViewModel: \(self.locations.count) locations")
            }
    }

    func fetchProducts(code: String) {
        db.collection("conferences/\(code)/products")
            .order(by: "sort_order", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Products")
                    return
                }

                self.products = docs.compactMap { queryDocumentSnapshot -> Product? in
                    do {
                        return try queryDocumentSnapshot.data(as: Product.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                print("InfoViewModel: \(self.products.count) products")
            }
    }

    func fetchEvents(code: String) {
        db.collection("conferences/\(code)/events")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Events")
                    return
                }

                self.events = docs.compactMap { queryDocumentSnapshot -> Event? in
                    do {
                        return try queryDocumentSnapshot.data(as: Event.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                print("InfoViewModel: \(self.events.count) events")
            }
    }

    func fetchSpeakers(code: String) {
        db.collection("conferences/\(code)/speakers")
            .order(by: "name", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Speakers")
                    return
                }

                self.speakers = docs.compactMap { queryDocumentSnapshot -> Speaker? in
                    do {
                        return try queryDocumentSnapshot.data(as: Speaker.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                self.speakers.sort(using: KeyPathComparator(\.self.name, comparator: .localizedStandard))
            }
    }

    func fetchOrgs(code: String) {
        db.collection("conferences/\(code)/organizations")
            .order(by: "name", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.orgs = docs.compactMap { queryDocumentSnapshot -> Organization? in
                    do {
                        return try queryDocumentSnapshot.data(as: Organization.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                self.orgs.sort(using: KeyPathComparator(\.self.name, comparator: .localizedStandard))
                print("InfoViewModel: \(self.orgs.count) organizations")
            }
    }

    func fetchLists(code: String) {
        db.collection("conferences/\(code)/faqs")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.faqs = docs.compactMap { queryDocumentSnapshot -> FAQ? in
                    do {
                        return try queryDocumentSnapshot.data(as: FAQ.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                // NSLog("InfoViewModel: Documents: \(self.documents.count)")
            }
        db.collection("conferences/\(code)/articles")
            .order(by: "updated_at", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.news = docs.compactMap { queryDocumentSnapshot -> Article? in
                    do {
                        return try queryDocumentSnapshot.data(as: Article.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                // NSLog("InfoViewModel: Documents: \(self.documents.count)")
            }
    }
}
