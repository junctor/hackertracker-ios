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
    @Published var documents = [Document]()
    @Published var tagtypes = [TagType]()
    @Published var locations = [Location]()
    @Published var products = [Product]()
    @Published var content = [Content]()
    @Published var events = [Event]()
    @Published var speakers = [Speaker]()
    @Published var orgs = [Organization]()
    @Published var faqs = [FAQ]()
    @Published var news = [Article]()
    @Published var menus = [InfoMenu]()
    @Published var showLocaltime = false
    @Published var showPastEvents = true
    @Published var showNews = true
    @Published var colorMode = false
    @Published var outOfStock = false

    private var db = Firestore.firestore()

    func fetchData(code: String, hidden: Bool = false) {
        fetchConference(code: code)
        fetchDocuments(code: code)
        fetchTagTypes(code: code)
        fetchLocations(code: code)
        fetchProducts(code: code)
        self.events = []
        // fetchEvents(code: code)
        fetchContent(code: code)
        fetchSpeakers(code: code)
        fetchOrgs(code: code)
        fetchLists(code: code)
        fetchMenus(code: code)
    }

    func fetchConference(code: String) {
        db.collection("conferences")
            .document(code)
            .addSnapshotListener { documentSnapshot, error in
                guard let doc = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                
                do {
                    self.conference = try doc.data(as: Conference.self)
                } catch {
                    print("Error \(error)")
                    return
                }
                
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

    func fetchDocuments(code: String) {
        db.collection("conferences")
            .document(code)
            .collection("documents")
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
        db.collection("conferences")
            .document(code)
            .collection("tagtypes")
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
        db.collection("conferences")
            .document(code)
            .collection("locations")
            .order(by: "peer_sort_order", descending: false)
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
        db.collection("conferences")
            .document(code)
            .collection("products")
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

    /* func fetchEvents(code: String) {
        db.collection("conferences")
            .document(code)
            .collection("events")
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
    } */
    
    func fetchContent(code: String) {
        db.collection("conferences")
            .document(code)
            .collection("content")
            .order(by: "title", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Content")
                    return
                }

                self.content = docs.compactMap { queryDocumentSnapshot -> Content? in
                    do {
                        self.events = []
                        return try queryDocumentSnapshot.data(as: Content.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                for c in self.content {
                    if !c.sessions.isEmpty {
                        for s in c.sessions {
                            if let _ = self.events.first(where: {$0.id == s.id}) {
                                // Don't do anything
                            } else {
                                let e = Event(id: s.id, contentId: c.id, description: c.description, beginTimestamp: s.beginTimestamp, endTimestamp: s.endTimestamp, title: c.title, locationId: s.locationId, people: c.people, tagIds: c.tagIds)
                                self.events.append(e)
                            }
                        }
                    }
                }

                print("InfoViewModel: \(self.content.count) content")
            }
    }

    func fetchSpeakers(code: String) {
        db.collection("conferences")
            .document(code)
            .collection("speakers")
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
        db.collection("conferences")
            .document(code)
            .collection("organizations")
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
        db.collection("conferences")
            .document(code)
            .collection("faqs")
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
        db.collection("conferences")
            .document(code)
            .collection("articles")
            .order(by: "updated_at", descending: true).addSnapshotListener { querySnapshot, error in
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
    
    func fetchMenus(code: String) {
        db.collection("conferences")
            .document(code)
            .collection("menus")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Menu Items")
                    return
                }

                self.menus = docs.compactMap { queryDocumentSnapshot -> InfoMenu? in
                    do {
                        return try queryDocumentSnapshot.data(as: InfoMenu.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                print("InfoViewModel: \(self.menus.count) menus")
            }
    }
}
