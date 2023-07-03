//
//  InfoViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/23.
//

import FirebaseFirestore
import Foundation
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

    private var db = Firestore.firestore()

    func fetchData(code: String, hidden: Bool = false) {
        self.fetchConference(code: code)
        self.fetchConferences(hidden: hidden)
        self.fetchDocuments(code: code)
        self.fetchTagTypes(code: code)
        self.fetchLocations(code: code)
        self.fetchProducts(code: code)
        self.fetchEvents(code: code)
        self.fetchSpeakers(code: code)
        self.fetchOrgs(code: code)
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
                        print("Location Parsing Error: \(error)")
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
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
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
                print("InfoViewModel: \(self.speakers.count) speakers")
            }
    }
    
    func fetchOrgs(code: String) {
        db.collection("conferences/\(code)/organizations")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
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
                print("InfoViewModel: \(self.orgs.count) organizations")
            }
    }
}
