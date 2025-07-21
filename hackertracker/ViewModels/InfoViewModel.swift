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
    @Published var feedbackForms = [FeedbackForm]()
    // @Published var showLocaltime = false
    @Published var showPastEvents = true
    @Published var showNews = true
    // @Published var colorMode = false
    @Published var outOfStock = false
    @Published var easterEgg = false
    var conferenceListener: ListenerRegistration?
    var documentListener: ListenerRegistration?
    var tagListener: ListenerRegistration?
    var locationListener: ListenerRegistration?
    var productListener: ListenerRegistration?
    var contentListener: ListenerRegistration?
    var speakerListener: ListenerRegistration?
    var orgListener: ListenerRegistration?
    var listListener: ListenerRegistration?
    var articleListener: ListenerRegistration?
    var menuListener: ListenerRegistration?
    @AppStorage("notifyAt") var notifyAt: Int = 20

    private var db = Firestore.firestore()

    func fetchData(code: String, hidden: Bool = false) {
        self.removeListeners()
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
        fetchFeedbackForms(code: code)
    }
    
    func removeListeners() {
        // print("Removing listeners")
        // print("DB Cache Settings: \(db.settings.isPersistenceEnabled)")
        if let cl = conferenceListener {
            cl.remove()
        }
        if let dl = documentListener {
            dl.remove()
        }
        if let tl = tagListener {
            tl.remove()
        }
        if let ll = locationListener {
            ll.remove()
        }
        if let pl = productListener {
            pl.remove()
        }
        if let cl = contentListener {
            cl.remove()
        }
        if let sl = speakerListener {
            sl.remove()
        }
        if let ll = listListener {
            ll.remove()
        }
        if let al = articleListener {
            al.remove()
        }
        if let ml = menuListener {
            ml.remove()
        }
    }

    func fetchConference(code: String) {
        conferenceListener = db.collection("conferences")
            .document(code)
            .addSnapshotListener { documentSnapshot, error in
                guard let doc = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                
                do {
                    self.conference = try doc.data(as: Conference.self)
                    if doc.metadata.isFromCache {
                        NSLog("Pulling conference \(self.conference?.code ?? "none") data from cache")
                    } else {
                        NSLog("Pulling conference \(self.conference?.code ?? "none") data from firestore")
                    }
                } catch {
                    print("Error \(error)")
                    return
                }
                
                print("InfoViewModel: Conference selected: \(self.conference?.name ?? "none")")
                if let conference = self.conference, let maps = conference.maps, maps.count > 0 {
                    let fileManager = FileManager.default
                    let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    
                    for map in maps {
                        if let url = URL(string: map.url) {
                            let path = "\(conference.code)/\(url.lastPathComponent)"
                            let mLocalDir = docDir.appendingPathComponent(conference.code)
                            if !FileManager.default.fileExists(atPath: mLocalDir.path) {
                                try! FileManager.default.createDirectory(at: mLocalDir, withIntermediateDirectories: true)
                            }
                            // let mRef = storageRef.child(conference.code)
                            let mLocal = docDir.appendingPathComponent(path)
                            if fileManager.fileExists(atPath: mLocal.path) {
                                // Add logic to check md5 hash and re-update if it has changed
                                NSLog("InfoViewModel: (\(conference.code): Map file (\(path)) already exists")
                            } else {
                                /* _ = mRef.write(toFile: mLocal) { _, error in
                                    if let error = error {
                                        print("InfoViewModel: (\(conference.code)): Error \(error) retrieving \(path)")
                                    } else {
                                        print("InfoViewModel: (\(conference.code)): Got map \(path)")
                                    }
                                } */
                                self.downloadFileCompletionHandler(url: url, destinationUrl: mLocal) { (destinationUrl, error) in
                                    if let durl = destinationUrl {
                                        NSLog("Finished downloading: \(durl)")
                                    } else {
                                        print(error!)
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }
    
    private func downloadFileCompletionHandler(url: URL, destinationUrl: URL, completion: @escaping (URL?, Error?) -> Void) {

            /* let url = URL(string: urlstring)!
            let documentsUrl =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
             */
            print(destinationUrl)

            if FileManager().fileExists(atPath: destinationUrl.path) {
                print("File already exists [\(destinationUrl.path)]")
    //            try! FileManager().removeItem(at: destinationUrl)
                completion(destinationUrl, nil)
                return
            }

            let request = URLRequest(url: url)


            let task = URLSession.shared.downloadTask(with: request) { tempFileUrl, response, error in
    //            print(tempFileUrl, response, error)
                if error != nil {
                    completion(nil, error)
                    return
                }

                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        if let tempFileUrl = tempFileUrl {
                            print("download finished")
                            if FileManager().fileExists(atPath: destinationUrl.path) {
                                try! FileManager.default.removeItem(at: destinationUrl)
                            }
                                try! FileManager.default.moveItem(at: tempFileUrl, to: destinationUrl)
                            completion(destinationUrl, error)
                        } else {
                            completion(nil, error)
                        }

                    }
                }

            }
            task.resume()
        }

    func fetchDocuments(code: String) {
        documentListener = db.collection("conferences")
            .document(code)
            .collection("documents")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }
                var cache = 0
                var firestore = 0
                self.documents = docs.compactMap { queryDocumentSnapshot -> Document? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: Document.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                NSLog("InfoViewModel: \(self.documents.count) documents (cache hits \(cache), firestore hits \(firestore))")
            }
    }

    func fetchTagTypes(code: String) {
        tagListener = db.collection("conferences")
            .document(code)
            .collection("tagtypes")
            .order(by: "sort_order", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Tags")
                    return
                }
                var cache = 0
                var firestore = 0
                self.tagtypes = docs.compactMap { queryDocumentSnapshot -> TagType? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: TagType.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                NSLog("InfoViewModel: \(self.tagtypes.count) tags (cache hits \(cache), firestore hits \(firestore))")
            }
    }

    func fetchLocations(code: String) {
        locationListener = db.collection("conferences")
            .document(code)
            .collection("locations")
            .order(by: "peer_sort_order", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Locations")
                    return
                }
                var cache = 0
                var firestore = 0
                self.locations = docs.compactMap { queryDocumentSnapshot -> Location? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: Location.self)
                    } catch {
                        print("fetchLocations: Location Parsing Error: \(error)")
                        print("fetchLocations: Code: \(code)")
                        print("fetchLocations: qds: \(queryDocumentSnapshot.data())")
                        return nil
                    }
                }
                NSLog("InfoViewModel: \(self.locations.count) locations (cache hits \(cache), firestore hits \(firestore))")
            }
    }

    func fetchProducts(code: String) {
        productListener = db.collection("conferences")
            .document(code)
            .collection("products")
            .order(by: "sort_order", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Products")
                    return
                }
                var cache = 0
                var firestore = 0
                self.products = docs.compactMap { queryDocumentSnapshot -> Product? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: Product.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                NSLog("InfoViewModel: \(self.products.count) products (cache hits \(cache), firestore hits \(firestore))")
            }
    }
    
    func fetchContent(code: String) {
        contentListener = db.collection("conferences")
            .document(code)
            .collection("content")
            .order(by: "title", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Content")
                    return
                }

                var cache = 0
                var firestore = 0
                self.content = docs.compactMap { queryDocumentSnapshot -> Content? in
                    do {
                        self.events = []
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
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
                                let e = Event(id: s.id, contentId: c.id, description: c.description, beginTimestamp: s.beginTimestamp, endTimestamp: s.endTimestamp, title: c.title, locationId: s.locationId, people: c.people, tagIds: c.tagIds, relatedIds: c.relatedIds)
                                self.events.append(e)
                                /* Task {
                                    if await NotificationUtility.notificationExists(id: e.id) {
                                        NotificationUtility.removeNotification(id: e.id)
                                        let notDate = e.beginTimestamp.addingTimeInterval(Double((-self.notifyAt)) * 60)
                                        NotificationUtility.scheduleNotification(date: notDate, id: e.id, title: e.title, location: self.locations.first(where: {$0.id == e.locationId})?.name ?? "unknown")
                                    }
                                } */
                            }
                        }
                    }
                }

                NSLog("InfoViewModel: \(self.content.count) content (cache hits \(cache), firestore hits \(firestore))")
            }
    }

    func fetchSpeakers(code: String) {
        speakerListener = db.collection("conferences")
            .document(code)
            .collection("speakers")
            .order(by: "name", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Speakers")
                    return
                }

                var cache = 0
                var firestore = 0
                self.speakers = docs.compactMap { queryDocumentSnapshot -> Speaker? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: Speaker.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                self.speakers.sort(using: KeyPathComparator(\.self.name, comparator: .localizedStandard))
                NSLog("InfoViewModel: \(self.speakers.count) speakers (cache hits \(cache), firestore hits \(firestore))")
            }
    }

    func fetchOrgs(code: String) {
        orgListener = db.collection("conferences")
            .document(code)
            .collection("organizations")
            .order(by: "name", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                var cache = 0
                var firestore = 0
                self.orgs = docs.compactMap { queryDocumentSnapshot -> Organization? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: Organization.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                self.orgs.sort(using: KeyPathComparator(\.self.name, comparator: .localizedStandard))
                NSLog("InfoViewModel: \(self.orgs.count) organizations (cache hits \(cache), firestore hits \(firestore))")
            }
    }

    func fetchLists(code: String) {
        listListener = db.collection("conferences")
            .document(code)
            .collection("faqs")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                var cache = 0
                var firestore = 0
                self.faqs = docs.compactMap { queryDocumentSnapshot -> FAQ? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: FAQ.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                NSLog("InfoViewModel: FAQs: \(self.faqs.count) (cache hits \(cache), firestore hits \(firestore))")
            }
        articleListener = db.collection("conferences")
            .document(code)
            .collection("articles")
            .order(by: "updated_at", descending: true).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                var cache = 0
                var firestore = 0
                self.news = docs.compactMap { queryDocumentSnapshot -> Article? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: Article.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                NSLog("InfoViewModel: News Articles: \(self.news.count) (cache hits \(cache), firestore hits \(firestore))")
            }
    }
    
    func fetchMenus(code: String) {
        menuListener = db.collection("conferences")
            .document(code)
            .collection("menus")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Menu Items")
                    return
                }

                var cache = 0
                var firestore = 0
                self.menus = docs.compactMap { queryDocumentSnapshot -> InfoMenu? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: InfoMenu.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                print("InfoViewModel: \(self.menus.count) menus (cache hits \(cache), firestore hits \(firestore))")
            }
    }
    
    func fetchFeedbackForms(code: String) {
        productListener = db.collection("conferences")
            .document(code)
            .collection("feedbackforms")
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Products")
                    return
                }

                var cache = 0
                var firestore = 0
                self.feedbackForms = docs.compactMap { queryDocumentSnapshot -> FeedbackForm? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: FeedbackForm.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                print("InfoViewModel: \(self.feedbackForms.count) feedback forms (cache hits \(cache), firestore hits \(firestore))")
            }
    }
}
