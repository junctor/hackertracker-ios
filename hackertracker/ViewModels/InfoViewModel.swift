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
    @Published var events = [Event]() {
        didSet {
            // Phase 2: O(1) event lookup so bookmarkConflicts is O(b) instead of O(b*n).
            eventsById = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
            conflictCache.removeAll(keepingCapacity: true)
        }
    }
    /// Phase 2: index rebuilt whenever `events` changes.
    private var eventsById: [Int: Event] = [:]
    /// Phase 2: cached per-event conflict result for a given bookmark set.
    /// Cleared when events change or bookmarks change.
    private var conflictCache: [Int: Bool] = [:]
    private var conflictCacheBookmarkKey: Int = 0
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
    var feedbackFormsListener: ListenerRegistration?
    @AppStorage("notifyAt") var notifyAt: Int = 20

    deinit {
        // Phase 1 fix: root-level @StateObjects rarely deallocate, but if they do (e.g. in
        // tests or previews) the listeners would keep streaming forever otherwise.
        removeListenersImmediate()
    }

    private var db = Firestore.firestore()
    
    func bookmarkConflicts(eventId: Int, bookmarks: [Int]) -> Bool {
        // Phase 2: O(1) dict lookup + per-event memoization keyed on bookmark identity.
        var hasher = Hasher()
        for b in bookmarks { hasher.combine(b) }
        let bookmarkKey = hasher.finalize()
        if bookmarkKey != conflictCacheBookmarkKey {
            conflictCache.removeAll(keepingCapacity: true)
            conflictCacheBookmarkKey = bookmarkKey
        }
        if let cached = conflictCache[eventId] { return cached }
        guard let e = eventsById[eventId] else {
            conflictCache[eventId] = false
            return false
        }
        for bookmark in bookmarks where bookmark != eventId {
            guard let be = eventsById[bookmark] else { continue }
            if be.beginTimestamp == e.beginTimestamp || be.endTimestamp == e.endTimestamp ||
               (be.beginTimestamp >= e.beginTimestamp && be.beginTimestamp <= e.endTimestamp) ||
               (be.endTimestamp >= e.beginTimestamp && be.endTimestamp <= e.endTimestamp) ||
               (e.beginTimestamp >= be.beginTimestamp && e.beginTimestamp <= be.endTimestamp) ||
               (e.endTimestamp >= be.beginTimestamp && e.endTimestamp <= be.endTimestamp) {
                conflictCache[eventId] = true
                return true
            }
        }
        conflictCache[eventId] = false
        return false
    }
    
    func bookmarkConflicts(bookmarks: [Int]) -> Bool {
        for bookmark in bookmarks {
            if bookmarkConflicts(eventId: bookmark, bookmarks: bookmarks) {
                return true
            }
        }
        return false
    }

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
        if let fl = feedbackFormsListener {
            fl.remove()
        }
    }

    /// deinit-safe variant that doesn't touch @Published state.
    private func removeListenersImmediate() {
        conferenceListener?.remove()
        documentListener?.remove()
        tagListener?.remove()
        locationListener?.remove()
        productListener?.remove()
        contentListener?.remove()
        speakerListener?.remove()
        orgListener?.remove()
        listListener?.remove()
        articleListener?.remove()
        menuListener?.remove()
        feedbackFormsListener?.remove()
    }

    func fetchConference(code: String) {
        conferenceListener = db.collection("conferences")
            .document(code)
            .addSnapshotListener { documentSnapshot, error in
                guard let doc = documentSnapshot else {
                    Log.firestore.error("conference fetch failed: \(String(describing: error), privacy: .public)")
                    if let e = error { CrashReport.record(e, context: ["op": "fetchConference"]) }
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
                    Log.firestore.error("conference decode failed: \(error, privacy: .public)")
                    CrashReport.record(error, context: ["op": "decodeConference"])
                    return
                }
                
                Log.app.info("conference selected: \(self.conference?.name ?? "none", privacy: .public)")
                if let conference = self.conference, let maps = conference.maps, maps.count > 0 {
                    let fileManager = FileManager.default
                    let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    
                    for map in maps {
                        if let url = URL(string: map.url) {
                            let path = "\(conference.code)/\(url.lastPathComponent)"
                            let mLocal = docDir.appendingPathComponent(path)
                            if !fileManager.fileExists(atPath: mLocal.deletingLastPathComponent().path) {
                                do {
                                    try fileManager.createDirectory(at: mLocal.deletingLastPathComponent(), withIntermediateDirectories: true)
                                } catch {
                                    Log.network.error("map dir create failed: \(error.localizedDescription, privacy: .public)")
                                    CrashReport.record(error, context: ["op": "createMapDir", "path": path])
                                    continue
                                }
                            }
                            
                            if fileManager.fileExists(atPath: mLocal.path) {
                                // Add logic to check md5 hash and re-update if it has changed
                                NSLog("InfoViewModel: (\(conference.code): Map file (\(path)) already exists")
                            } else {
                                self.downloadFileCompletionHandler(url: url, destinationUrl: mLocal) { (destinationUrl, error) in
                                    if let durl = destinationUrl {
                                        NSLog("Finished downloading: \(durl)")
                                    } else {
                                        Log.firestore.error("map storage error: \(String(describing: error), privacy: .public)")
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
            Log.network.debug("download dest: \(destinationUrl.lastPathComponent, privacy: .public)")

            if FileManager().fileExists(atPath: destinationUrl.path) {
                Log.network.debug("file already exists: \(destinationUrl.lastPathComponent, privacy: .public)")
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
                            Log.network.debug("download finished")
                            // Phase 1 fix: all three filesystem ops below were try! — sandbox
                            // races or disk-full would crash the app.
                            if FileManager().fileExists(atPath: destinationUrl.path) {
                                do {
                                    try FileManager.default.removeItem(at: destinationUrl)
                                } catch {
                                    Log.network.error("removeItem failed: \(error.localizedDescription, privacy: .public)")
                                    CrashReport.record(error, context: ["op": "removeExistingMap"])
                                    completion(nil, error)
                                    return
                                }
                            }
                            let directoryPath = (destinationUrl.path as NSString).deletingLastPathComponent
                            if !FileManager.default.fileExists(atPath: directoryPath) {
                                do {
                                    try FileManager.default.createDirectory(at: destinationUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
                                } catch {
                                    Log.network.error("createDirectory failed: \(error.localizedDescription, privacy: .public)")
                                    CrashReport.record(error, context: ["op": "createDirectory"])
                                    completion(nil, error)
                                    return
                                }
                            }
                            do {
                                try FileManager.default.moveItem(at: tempFileUrl, to: destinationUrl)
                                completion(destinationUrl, error)
                            } catch {
                                Log.network.error("moveItem failed: \(error.localizedDescription, privacy: .public)")
                                CrashReport.record(error, context: ["op": "moveDownloadedMap"])
                                completion(nil, error)
                            }
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
                    Log.firestore.info("documents: empty snapshot")
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
                        Log.firestore.error("document decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeDocument"])
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
                    Log.firestore.info("tags: empty snapshot")
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
                        Log.firestore.error("tag decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeTag"])
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
                    Log.firestore.info("locations: empty snapshot")
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
                        Log.firestore.error("location decode failed code=\(code, privacy: .public): \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeLocation", "code": code])
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
                    Log.firestore.info("products: empty snapshot")
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
                        Log.firestore.error("product decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeProduct"])
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
                    Log.firestore.info("content: empty snapshot")
                    return
                }

                var cache = 0
                var firestore = 0
                // Phase 1 fix: previously `self.events = []` lived inside the per-document
                // compactMap, so each decoded doc reset events and a concurrent snapshot
                // mid-decode could duplicate or drop entries. Build a local buffer first,
                // then assign atomically once decoding completes.
                let decodedContent: [Content] = docs.compactMap { queryDocumentSnapshot -> Content? in
                    do {
                        if queryDocumentSnapshot.metadata.isFromCache {
                            cache = cache + 1
                        } else {
                            firestore = firestore + 1
                        }
                        return try queryDocumentSnapshot.data(as: Content.self)
                    } catch {
                        Log.firestore.error("content decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeContent"])
                        return nil
                    }
                }
                var rebuiltEvents: [Event] = []
                var seenEventIds: Set<Int> = []
                for c in decodedContent {
                    if !c.sessions.isEmpty {
                        for s in c.sessions {
                            if seenEventIds.contains(s.id) {
                                continue
                            }
                            seenEventIds.insert(s.id)
                            let e = Event(id: s.id, contentId: c.id, description: c.description, beginTimestamp: s.beginTimestamp, endTimestamp: s.endTimestamp, title: c.title, locationId: s.locationId, people: c.people, tagIds: c.tagIds, relatedIds: c.relatedIds)
                            rebuiltEvents.append(e)
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
                self.content = decodedContent
                self.events = rebuiltEvents

                NSLog("InfoViewModel: \(self.content.count) content (cache hits \(cache), firestore hits \(firestore))")
            }
    }

    func fetchSpeakers(code: String) {
        speakerListener = db.collection("conferences")
            .document(code)
            .collection("speakers")
            .order(by: "name", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    Log.firestore.info("speakers: empty snapshot")
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
                        Log.firestore.error("speaker decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeSpeaker"])
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
                    Log.firestore.info("orgs: empty snapshot")
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
                        Log.firestore.error("org decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeOrg"])
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
                    Log.firestore.info("faqs: empty snapshot")
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
                        Log.firestore.error("faq decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeFAQ"])
                        return nil
                    }
                }
                NSLog("InfoViewModel: FAQs: \(self.faqs.count) (cache hits \(cache), firestore hits \(firestore))")
            }
        articleListener = db.collection("conferences")
            .document(code)
            .collection("articles")
            .order(by: "updated_at", descending: true)
            // Phase 2: cap news feed; older articles can be loaded on demand later.
            .limit(to: 100)
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    Log.firestore.info("articles: empty snapshot")
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
                        Log.firestore.error("article decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeArticle"])
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
                    Log.firestore.info("menus: empty snapshot")
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
                        Log.firestore.error("menu decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeMenu"])
                        return nil
                    }
                }
                Log.app.debug("menus loaded: \(self.menus.count) (cache=\(cache), firestore=\(firestore))")
            }
    }
    
    func fetchFeedbackForms(code: String) {
        // Phase 1 fix: previously this clobbered productListener, leaking the products
        // snapshot listener and breaking products fetches on reuse.
        feedbackFormsListener = db.collection("conferences")
            .document(code)
            .collection("feedbackforms")
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    Log.firestore.info("feedbackForms: empty snapshot")
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
                        Log.firestore.error("feedbackForm decode failed: \(error, privacy: .public)")
                        CrashReport.record(error, context: ["op": "decodeFeedbackForm"])
                        return nil
                    }
                }
                Log.app.debug("feedbackForms loaded: \(self.feedbackForms.count) (cache=\(cache), firestore=\(firestore))")
            }
    }
}
