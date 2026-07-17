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

// Phase 3b: migrated from ObservableObject to @Observable.
// Property-level change tracking; views that read only specific arrays
// (e.g. speakers) no longer re-render when an unrelated array (e.g. menus)
// updates.
// Phase 3c: @MainActor isolation. All published-state mutation now happens
// on the main actor. Each Firestore snapshot listener decodes in its Sendable
// closure (off-main when Firebase runs there), then hops onto MainActor via
// `Task { @MainActor in ... }` for the actual array assignment. This closes
// the SwiftUI "Publishing changes from background threads" warning surface
// and is a prerequisite for Swift 6 strict concurrency.
@Observable
@MainActor
final class InfoViewModel {
    var conference: Conference?
    var documents = [Document]() {
        didSet { documentsById = Dictionary(uniqueKeysWithValues: documents.map { ($0.id, $0) }) }
    }
    var tagtypes = [TagType]() {
        didSet {
            // Build a flat tag id -> TagType lookup so cells can resolve a tag's
            // parent TagType in O(1) instead of scanning all tagtypes per tag.
            var byTagId: [Int: TagType] = [:]
            var tagById: [Int: Tag] = [:]
            for tt in tagtypes {
                for tag in tt.tags {
                    byTagId[tag.id] = tt
                    tagById[tag.id] = tag
                }
            }
            tagTypeByTagId = byTagId
            tagsById = tagById
        }
    }
    var locations = [Location]() {
        didSet { locationsById = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) }) }
    }
    var products = [Product]() {
        didSet { productsById = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) }) }
    }
    var content = [Content]() {
        didSet { contentById = Dictionary(uniqueKeysWithValues: content.map { ($0.id, $0) }) }
    }

    // Phase Perf-A: id-keyed indexes rebuilt on each array assignment.
    // ObservationIgnored so dependents observe the source array, not the index.
    @ObservationIgnored private(set) var documentsById: [Int: Document] = [:]
    @ObservationIgnored private(set) var locationsById: [Int: Location] = [:]
    @ObservationIgnored private(set) var productsById: [Int: Product] = [:]
    @ObservationIgnored private(set) var contentById: [Int: Content] = [:]
    @ObservationIgnored private(set) var speakersById: [Int: Speaker] = [:]
    @ObservationIgnored private(set) var orgsById: [String: Organization] = [:]
    @ObservationIgnored private(set) var tagTypeByTagId: [Int: TagType] = [:]
    @ObservationIgnored private(set) var tagsById: [Int: Tag] = [:]
    var events = [Event]() {
        didSet {
            // Phase 2: O(1) event lookup so bookmarkConflicts is O(b) instead of O(b*n).
            eventsById = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
            conflictCache.removeAll(keepingCapacity: true)
        }
    }
    /// Phase 2: index rebuilt whenever `events` changes.
    /// Exposed as `private(set)` so views needing O(1) lookups
    /// (e.g. SpeakerRow's tag rollup) don't have to do O(n) scans.
    @ObservationIgnored private(set) var eventsById: [Int: Event] = [:]
    /// Phase 2: cached per-event conflict result for a given bookmark set.
    /// Cleared when events change or bookmarks change.
    @ObservationIgnored private var conflictCache: [Int: Bool] = [:]
    @ObservationIgnored private var conflictCacheBookmarkKey: Int = 0
    var speakers = [Speaker]() {
        didSet { speakersById = Dictionary(uniqueKeysWithValues: speakers.map { ($0.id, $0) }) }
    }
    var orgs = [Organization]() {
        didSet {
            var idx: [String: Organization] = [:]
            for org in orgs { if let id = org.id { idx[id] = org } }
            orgsById = idx
        }
    }
    var faqs = [FAQ]()
    var news = [Article]()
    var menus = [InfoMenu]()
    var feedbackForms = [FeedbackForm]()
    // @Published var showLocaltime = false
    var showPastEvents = true
    var showNews = true
    // @Published var colorMode = false
    var outOfStock = false
    var easterEgg = false
    /// True while one or more map asset downloads are in flight for
    /// the current conference. Drives the Maps tab icon's loading
    /// indicator. Files that already exist on disk don't increment
    /// the counter, so a returning user who already has every map
    /// cached never sees the spinner.
    var mapsLoading: Bool = false
    @ObservationIgnored private var pendingMapDownloads: Int = 0
    @ObservationIgnored nonisolated(unsafe) var conferenceListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var documentListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var tagListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var locationListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var productListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var contentListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var speakerListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var orgListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var listListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var articleListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var menuListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) var feedbackFormsListener: ListenerRegistration?

    deinit {
        // Phase 1 fix: root-level @StateObjects rarely deallocate, but if they do (e.g. in
        // tests or previews) the listeners would keep streaming forever otherwise.
        // Phase 3c: inlined so the @MainActor-isolated `removeListenersImmediate` doesn't
        // need to be called from a nonisolated deinit. `.remove()` is thread-safe.
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

    @ObservationIgnored private var db = Firestore.firestore()

    // Phase perf: generation counters guard the off-main decode path in
    // fetchContent/fetchSpeakers against out-of-order snapshot delivery.
    // Firestore can fire a cache tick immediately followed by a server tick;
    // if the cache-tick decode (dispatched first) happens to finish after the
    // server-tick decode, applying it would clobber fresher data with stale
    // data. Each fetcher captures the pre-increment generation before
    // detaching its decode Task, and the result is discarded unless its
    // generation is still the newest one issued for that fetcher.
    @ObservationIgnored private var contentGeneration = 0
    @ObservationIgnored private var speakerGeneration = 0

    func bookmarkConflicts(eventId: Int, bookmarks: [Int]) -> Bool {
        // Convenience overload: derives the bookmark identity key here.
        // Callers that render many rows against the same bookmark set
        // (EventCell) should precompute the key once (BookmarkSnapshot)
        // and use the overload below so the array isn't re-hashed per call.
        var hasher = Hasher()
        for b in bookmarks { hasher.combine(b) }
        return bookmarkConflicts(eventId: eventId, bookmarks: bookmarks, bookmarkKey: hasher.finalize())
    }

    func bookmarkConflicts(eventId: Int, bookmarks: [Int], bookmarkKey: Int) -> Bool {
        // Phase 2: O(1) dict lookup + per-event memoization keyed on bookmark identity.
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
            // Bugfix: previously used closed-interval checks (<=) which flagged
            // back-to-back events (10-11 and 11-12) as conflicting because the
            // shared boundary timestamp counted as overlap. Standard half-open
            // interval overlap: two intervals [a,b) and [c,d) overlap iff
            // a < d && c < b. Adjacent events with b == c no longer conflict.
            if be.beginTimestamp < e.endTimestamp && e.beginTimestamp < be.endTimestamp {
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
        // Bugfix: this used to hand-roll its own list of `if let ... .remove()`
        // and had drifted out of sync with removeListenersImmediate() /
        // deinit — it was missing orgListener, so fetchData() -> removeListeners()
        // followed by fetchOrgs() orphaned the previous conference's org
        // listener (leaked live Firestore listener + possible stale-data
        // clobber). Delegate to removeListenersImmediate() so there's a
        // single source of truth for "which listeners exist."
        removeListenersImmediate()
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
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self else { return }
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
                    
                    // Inline helper: download a single PDF/SVG asset for
                    // a map. Same on-disk layout as before — files land at
                    // <docs>/<code>/<lastPathComponent>.
                    //
                    // After a download lands (or if the file was already on
                    // disk) we proactively warm PDFDocumentCache so the
                    // first render of MapView is paint-only, no parse.
                    // PDFDocument(url:) on a multi-MB floor plan can stall
                    // the main thread for ~200-400ms; doing it here at app
                    // launch / conference-switch time pushes that cost out
                    // of the user's interaction path entirely.
                    let downloadAsset: (String) -> Void = { assetURLString in
                        guard let url = URL(string: assetURLString) else { return }
                        let path = "\(conference.code)/\(url.lastPathComponent)"
                        let mLocal = docDir.appendingPathComponent(path)
                        if !fileManager.fileExists(atPath: mLocal.deletingLastPathComponent().path) {
                            do {
                                try fileManager.createDirectory(at: mLocal.deletingLastPathComponent(), withIntermediateDirectories: true)
                            } catch {
                                Log.network.error("map dir create failed: \(error.localizedDescription, privacy: .public)")
                                CrashReport.record(error, context: ["op": "createMapDir", "path": path])
                                return
                            }
                        }
                        if fileManager.fileExists(atPath: mLocal.path) {
                            Log.network.debug("map asset cached: \(path, privacy: .public)")
                            if mLocal.pathExtension.lowercased() == "pdf" {
                                PDFDocumentCache.prewarm(mLocal)
                            }
                        } else {
                            self.mapDownloadStarted()
                            self.downloadFileCompletionHandler(url: url, destinationUrl: mLocal) { destinationUrl, error in
                                // URLSession callback runs off-main; hop
                                // back to MainActor to mutate observable
                                // state safely.
                                Task { @MainActor [weak self] in
                                    if let durl = destinationUrl {
                                        Log.network.debug("map asset downloaded: \(durl.lastPathComponent, privacy: .public)")
                                        if durl.pathExtension.lowercased() == "pdf" {
                                            PDFDocumentCache.prewarm(durl)
                                        }
                                    } else {
                                        Log.firestore.error("map storage error: \(String(describing: error), privacy: .public)")
                                    }
                                    self?.mapDownloadFinished()
                                }
                            }
                        }
                    }
                    for map in maps {
                        downloadAsset(map.url)
                        // SVG variant download — strictly URL-based per the
                        // server team. Use svg_url first, then svg_filename
                        // (only if it looks like a URL). Anything else is
                        // ignored; the page falls back to the PDF.
                        if let url = map.svgUrl,
                           !url.trimmingCharacters(in: .whitespaces).isEmpty {
                            downloadAsset(url)
                        } else if let filename = map.svgFilename,
                                  filename.lowercased().hasPrefix("http") {
                            downloadAsset(filename)
                        }
                    }
                }
            }
    }
    
    private func mapDownloadStarted() {
        pendingMapDownloads += 1
        if !mapsLoading { mapsLoading = true }
    }

    private func mapDownloadFinished() {
        pendingMapDownloads -= 1
        if pendingMapDownloads <= 0 {
            pendingMapDownloads = 0
            mapsLoading = false
        }
    }

    private func downloadFileCompletionHandler(url: URL, destinationUrl: URL, completion: @Sendable @escaping (URL?, Error?) -> Void) {

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
                            // Bugfix: statusCode == 200 but no temp file — treat as a
                            // failure so `completion` still fires exactly once instead
                            // of silently dropping the callback.
                            Log.network.error("download reported success but no temp file")
                            completion(nil, URLError(.badServerResponse))
                        }
                    } else {
                        // Bugfix: non-200 responses (404/500/etc) previously fell through
                        // without calling `completion` at all, which left
                        // pendingMapDownloads permanently incremented and the Maps tab
                        // spinner stuck on for the rest of the session.
                        Log.network.error("download failed with status \(response.statusCode, privacy: .public)")
                        completion(nil, URLError(.badServerResponse))
                    }
                } else {
                    // Bugfix: cast to HTTPURLResponse failed (non-HTTP response, or nil) —
                    // same "never call completion" hole as the non-200 branch above.
                    Log.network.error("download response was not an HTTPURLResponse")
                    completion(nil, URLError(.badServerResponse))
                }

            }
            task.resume()
        }

    func fetchDocuments(code: String) {
        documentListener = db.collection("conferences")
            .document(code)
            .collection("documents")
            .order(by: "id", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
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
            .order(by: "sort_order", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
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
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
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
            .order(by: "sort_order", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
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
            .order(by: "title", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
                guard let docs = querySnapshot?.documents else {
                    Log.firestore.info("content: empty snapshot")
                    return
                }

                // Phase perf: DEF CON has 1000+ content docs, so the Codable
                // decode + event rebuild below is expensive enough to cause a
                // visible main-thread stall if done inline in this listener
                // closure (which Firestore invokes on the main queue). Hop to a
                // detached task to do the heavy lifting off-main; only the
                // final array assignment comes back to the MainActor.
                self.contentGeneration += 1
                let generation = self.contentGeneration

                // firebase-ios-sdk 11.3+ declares QueryDocumentSnapshot
                // Sendable, so the docs array crosses the Task.detached
                // boundary directly — no @unchecked box needed.
                Task.detached(priority: .userInitiated) { [weak self] in
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
                                let e = Event(id: s.id, contentId: c.id, description: c.description, beginTimestamp: s.beginTimestamp, endTimestamp: s.endTimestamp, title: c.title, locationId: s.locationId, people: c.people, tagIds: c.tagIds, relatedIds: c.relatedIds, visibleAgeMin: c.visibleAgeMin)
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

                    await MainActor.run {
                        // Discard this result if a newer snapshot's decode already landed.
                        guard let self, generation == self.contentGeneration else { return }
                        self.content = decodedContent
                        self.events = rebuiltEvents
                        NSLog("InfoViewModel: \(self.content.count) content (cache hits \(cache), firestore hits \(firestore))")
                    }
                }
            }
    }

    func fetchSpeakers(code: String) {
        speakerListener = db.collection("conferences")
            .document(code)
            .collection("speakers")
            .order(by: "name", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
                guard let docs = querySnapshot?.documents else {
                    Log.firestore.info("speakers: empty snapshot")
                    return
                }

                // Phase perf: same off-main decode treatment as fetchContent —
                // speakers is one of the larger collections and is re-decoded
                // in full on every snapshot tick.
                self.speakerGeneration += 1
                let generation = self.speakerGeneration

                Task.detached(priority: .userInitiated) { [weak self] in
                    var cache = 0
                    var firestore = 0
                    var decodedSpeakers: [Speaker] = docs.compactMap { queryDocumentSnapshot -> Speaker? in
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
                    // Finding B: sort before assigning so there's exactly one
                    // didSet/observation invalidation per snapshot tick instead of two.
                    decodedSpeakers.sort(using: KeyPathComparator(\.self.name, comparator: .localizedStandard))

                    await MainActor.run {
                        guard let self, generation == self.speakerGeneration else { return }
                        self.speakers = decodedSpeakers
                        NSLog("InfoViewModel: \(self.speakers.count) speakers (cache hits \(cache), firestore hits \(firestore))")
                    }
                }
            }
    }

    func fetchOrgs(code: String) {
        orgListener = db.collection("conferences")
            .document(code)
            .collection("organizations")
            .order(by: "name", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
                guard let docs = querySnapshot?.documents else {
                    Log.firestore.info("orgs: empty snapshot")
                    return
                }

                var cache = 0
                var firestore = 0
                var decodedOrgs: [Organization] = docs.compactMap { queryDocumentSnapshot -> Organization? in
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
                // Finding B: sort the local array before assigning to `orgs`
                // so there's exactly one didSet/observation invalidation per tick.
                decodedOrgs.sort(using: KeyPathComparator(\.self.name, comparator: .localizedStandard))
                self.orgs = decodedOrgs
                NSLog("InfoViewModel: \(self.orgs.count) organizations (cache hits \(cache), firestore hits \(firestore))")
            }
    }

    func fetchLists(code: String) {
        listListener = db.collection("conferences")
            .document(code)
            .collection("faqs")
            .order(by: "id", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
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
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
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
            .order(by: "id", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
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
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self else { return }
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
